Throughout most of my programming career, I never felt an especially strong need
to learn how to automate my system administration work. Even though I knew that people were
doing cool stuff with tools like [Puppet][puppet] right around the same time
that Rails started getting popular, I had always assumed that infrastructure automation 
only mattered for high-traffic websites, internet service providers, and 
people building extremely complicated enterprise software. 

In my own work, I could typically count on one hand how many new systems needed to 
be provisioned in a year. Working on teams where someone else was usually
responsible for babysitting the servers, it never even occured to me to level up
my system administration skills, let alone learn a whole new way of doing
things. As long as I could get keep my own development environment in decent
working order, I was a happy guy.

For all of these reasons, my initial response to Mathias about covering
infrastructure automation in Practicing Ruby was somewhat ambivalent. I was
open to the idea, but still stuck in the mindset that such tools were highly
specialized and not important for everyday programmers to know about. I was even
worried that we would not be able to come up with good examples, because I had
always assumed that the main reason to automatically provision systems was to
make scaling easier, and maybe to avoid some of the dumb mistakes that
can easily happen during a manual setup process. 

(Complete this intro)

Recipes are self contained! (Somewhat)

## Setting up Ruby

http://fnichol.github.io/chef-ruby_build/
https://github.com/sstephenson/ruby-build


```ruby
# Install ruby-build
include_recipe "ruby_build"

# Build and install Ruby version using ruby-build. 
ruby_build_ruby node["practicingruby"]["ruby"]["version"]

# Update to the latest RubyGems version
bash "update-rubygems" do
  code   "gem update --system"
  not_if "gem list | grep -q rubygems-update"
end

# Install Bundler
gem_package "bundler"
```

Other recipes that are resource-only:

* `deploy_user`
* `postgresql`
* `mail_catcher` (Maybe? it also uses notifications... and a dubious "true" call)

## Setting up process monitoring

```ruby
# Install Ruby first
include_recipe "practicingruby::_ruby"

# Install god gem
gem_package "god"

# Create config directory
directory "/etc/god" do
  owner "root"
  group "root"
  mode  "0755"
end

# Create config file
cookbook_file "/etc/god/master.conf" do
  owner    "root"
  group    "root"
  mode     "0644"
  notifies :restart, "service[god]"

  home     = node["practicingruby"]["deploy"]["home_dir"] 
  god_file = "#{home}/current/config/delayed_job.god"

  content %{ God.load('#{god_file}') if File.file?('#{god_file}') }
end

# Install startup script
cookbook_file "/etc/init/god.conf" do
  source "god.upstart"
  owner  "root"
  group  "root"
  mode   "0644"
end

# Start god
service "god" do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true
  action   [:enable, :start]
end
```

^ Enable service to startup at boot, and also start it now.

Other recipes that use the same features:

*
*


```ruby
# The config file will be deployed by Capistrano.
config_file = "<%= @god_file %>"
God.load(config_file) if File.file?(config_file)
```


```
description "God is a monitoring framework written in Ruby"

start on runlevel [2345]
stop on runlevel [!2345]

pre-start exec god -c /etc/god/master.conf
post-stop exec god terminate
```

## Nginx setup

http://www.opscode.com/blog/2013/02/05/chef-11-in-depth-attributes-changes/

```ruby
# Override default Nginx attributes
node.set["nginx"]["worker_processes"]     = 4
node.set["nginx"]["worker_connections"]   = 768
node.set["nginx"]["default_site_enabled"] = false

# Install Nginx and set up nginx.conf
include_recipe "nginx::default"

# Create directory to store SSL files
ssl_dir = ::File.join(node["nginx"]["dir"], "ssl")
directory ssl_dir do
  owner "root"
  group "root"
  mode  "0600"
end

# Generate SSL private key and use it to issue self-signed certificate for
# currently configured domain name
domain_name = node["practicingruby"]["rails"]["host"]
bash "generate-ssl-files" do
  user  "root"
  cwd   ssl_dir
  flags "-e"
  code <<-EOS
    DOMAIN=#{domain_name}
    openssl genrsa -out $DOMAIN.key 4096
    openssl req -new -batch -subj "/CN=$DOMAIN" -key $DOMAIN.key -out $DOMAIN.csr
    openssl x509 -req -days 365 -in $DOMAIN.csr -signkey $DOMAIN.key -out $DOMAIN.crt
    rm $DOMAIN.csr
  EOS
  notifies :reload, "service[nginx]"
  not_if   { ::File.exists?(::File.join(ssl_dir, domain_name + ".crt")) }
end

# Create practicingruby site config
template "#{node["nginx"]["dir"]}/sites-available/practicingruby" do
  source "nginx_site.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables(:domain_name => domain_name)
end

# Enable practicingruby site
nginx_site "practicingruby" do
  enable true
end
```

Any recipes with features NOT used by this one or any previous ones?


[puppet]: http://puppetlabs.com
