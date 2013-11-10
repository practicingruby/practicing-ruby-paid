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

Let's start our exploration of Practicing Ruby's cookbook by taking a look
at how it handles its Ruby installation. The particular recipe we use is 
shown below:

```ruby
include_recipe "ruby_build"

ruby_version = node["practicingruby"]["ruby"]["version"]

ruby_build_ruby(ruby_version) { prefix_path "/usr/local" }

bash "update-rubygems" do
  code   "gem update --system"
  not_if "gem list | grep -q rubygems-update"
end

gem_package "bundler"
```

At the high level, this recipe is responsible for handling the following tasks: 

1. Installing the `ruby-build` command line tool.
2. Using `ruby-build` to compile and install Ruby to `/usr/local`.
3. Updating Rubygems to the latest version.
4. Installing the bundler gem.

Under the hood, a lot more is going on. Let's break the recipe down into its
parts and see what is actually being done. (reword)

1) The [ruby_build](http://fnichol.github.io/chef-ruby_build/) cookbook is
used to install the `ruby-build` command-line tool:

```ruby
include_recipe "ruby_build"
```

Including this recipe into our own gives us access to `ruby_build_ruby` command,
and also handles installing a bunch of low-level packages that are required to 
compile Ruby on an Ubuntu system.

2) The `ruby_build_ruby` command is used to install a particular version of
Ruby into `/usr/local`.

```ruby
ruby_version = node["practicingruby"]["ruby"]["version"]

ruby_build_ruby(ruby_version) { prefix_path "/usr/local" }
```

In our recipe, the version of Ruby we want to install is not specified
explicitly, but instead set elsewhere using Chef's attribute system.
If you look at our default attributes file, you'll find an entry that
looks like this:

```ruby
default["practicingruby"]["ruby"]["version"] = "2.0.0-p247"
```

Chef has a very flexible and very complicated system for managing these
attributes, but its main purpose is the same as any configuration system:
to keep source code as generic as possible by not hard-coding
application-specific values. In our cookbook, we stick to very
simple uses of attributes, so we won't get bogged down in the
details of all the different ways they can be used in Chef.

3) Rubygems is updated to the latest version.

```ruby
bash "update-rubygems" do
  code   "gem update --system"
  not_if "gem list | grep -q rubygems-update"
end
```

4) The bundler gem is installed.

```ruby
gem_package "bundler"
```
Recipes are self contained! (Somewhat)

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
file "/etc/god/master.conf" do
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

**Working with files**

```ruby
# The config file will be deployed by Capistrano.
config_file = "<%= @god_file %>"
God.load(config_file) if File.file?(config_file)
```

**Managing services**

```
description "God is a monitoring framework written in Ruby"

start on runlevel [2345]
stop on runlevel [!2345]

pre-start exec god -c /etc/god/master.conf
post-stop exec god terminate
```


Enable service to startup at boot, and also start it now.


> UPSTART: I mainly did it for three reasons:

> * Consistency: Upstart is the standard init daemon under Ubuntu. As
the MailCatcher cookbook also utilizes Upstart, I thought I'd use it
for Unicorn too. That worked out well, so I decided to rewrite God's
init script as well. Now all our startup scripts make use of the same
mechanism.

> * Simplicity: This diff says it all:
https://github.com/elm-city-craftworks/practicing-ruby-cookbook/pull/11/files
Once you know how Upstart works, it's just way more easy to use than
LSB init scripts. For example, I didn't like how we had to define
runlevels before:
https://github.com/elm-city-craftworks/practicing-ruby-cookbook/pull/6/files

> * Learning/Experience: I've always wanted to write startup scripts
using something different than plain old shell scripts. 


## Nginx setup

http://www.opscode.com/blog/2013/02/05/chef-11-in-depth-attributes-changes/

> The first two lines are most certainly copied directly from the Unicorn nginx config file I used. Turning off the default site does exactly that, turns off nginx’s default “Welcome to nginx” page which is on by default.

> The nginx cookbook manages nginx.conf for us. I only had to
change the number of worker processes and worker connections to mirror
what's used in production (i.e. the nginx.conf Jordan sent me).

> However, the cookbook cannot manage site configurations via
attributes; it can merely enable or disable them. That's why our site
config is first written via `template` and then enabled via the
cookbook's `nginx_site` helper.



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

**Advanced shell usage**

**Using Templates**

Note nginx.conf vs. site


## Everything else



[puppet]: http://puppetlabs.com




