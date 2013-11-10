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

* Installing the `ruby-build` command line tool.
* Using `ruby-build` to compile and install Ruby to `/usr/local`.
* Updating Rubygems to the latest version.
* Installing the bundler gem.

```ruby
include_recipe "ruby_build"
```

discuss side effect of including this recipe... install is run
and `ruby_build_ruby` becomes available.

```ruby
ruby_version = node["practicingruby"]["ruby"]["version"]

ruby_build_ruby(ruby_version) { prefix_path "/usr/local" }
```

note why `/usr/local`, discuss attributes

```ruby
bash "update-rubygems" do
  code   "gem update --system"
  not_if "gem list | grep -q rubygems-update"
end
```

note idempotence

```
gem_package "bundler"
```

(note that we luck out here because of using /usr/local), a non-standard Ruby
installation would require you to specify the path the the gem executable.)

http://fnichol.github.io/chef-ruby_build/
https://github.com/sstephenson/ruby-build



The main difference between this recipe and a shell script to accomplish the same task is that it is written at a much higher level of abstraction. This makes it possible for the Chef platform to provide robust error handling, consistency checks, dependency management, and other useful features that would be cumbersome to implement manually in a shell script.

Even in this very basic example, we can see a tangible benefit of using Chef. If you were to attempt to manually install ruby-build on an Ubuntu system, you would also need to install the git-core, libssl-dev, and zlib1g-dev packages. To know that, you'd either need to find out by trial and error or dig through the wiki page for ruby-build to find a note about these dependencies. The cookbook we used to install ruby-build took care of installing these packages for us, giving us one less thing to think about when configuring our systems, and one less stumbling block to trip over.

But wherever there is a benefit, there are also costs. Unlike a shell script which can be directly executed without any complicated setup, Chef recipes need to be packaged up in "cookbooks" before they can do anything useful, and some additional underplumbing is also needed to manage the cookbooks themselves. Let's take a moment now to briefly explore what it takes to get all those building blocks into place.


**External resources**

**Shell resource**

**Attributes**


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
