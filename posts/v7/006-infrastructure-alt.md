For at least as long as Ruby has been popular among web developers, it has also
been recognized as a useful tool for system administration work. Although it was
first used as a clean alternative to Perl for adhoc scripting, Ruby quickly
evolved to the point where it became an excellent platform for large scale 
infrastructure automation projects. 

In this article, we'll explore realistic code that handles various system
automation tasks, and discuss what benefits an automated approach has over 
doing things the old-fashioned way. We'll also see first-hand what it means to treat
"infrastructure as code", and what the implications of that are.

## Prologue: Why does infrastructure automation matter?

Two massive systems have been built to facilitate infrastructure automation in 
Ruby (Puppet and Chef), both of which have entire open-source
ecosystems supporting them. But because these frameworks were built by and for
system administrators, infrastructure automation is often viewed as a
specialized skillset by Ruby programmers, rather than something that everyone
should learn. This is probably an incorrect viewpoint, but it is one that is
easy to hold without realizing the consequences.

Speaking from my own experiences, I always assumed that infrastructure
automation was a problem that mattered mostly for large-scale public web
applications, internet service providers, and very complicated enterprise
projects. In those kinds of environments, the cost of manually setting up
servers would obviously be high enough to justify using a 
sophisticated automation framework. But because I never encountered those
scenarios in my own work, I was content to do things the old-fasioned way:
reading lots of "works for me" instructions from blog posts, manually typing
commands on the console, and swearing loudly whenever I broke something. For
things that really matter or tasks that seemed too tough for me to do on my own,
I'd find someone else to take care of it for me.

The fundamental problems was that I had always focused on the fact that my
system-administration related pain wasn't enough for me to worry about learning 
a whole new of doing things. In making that assumption, I missed the fact that
infrastructure automation has other benefits beyond eliminating the costs
of doing repetitive and error-prone manual configuration work. In particular,
I vastly underestimated the value of treating "infrastructure as code",
especially as it relates to creating systems that are abstract, modular,
testable, understandable, and utterly hackable. Narrowing the problem down to
the single issue of reducing repetitive labor, I had failed to see that
infrastructure automation has the potential to eliminate an entire class of
problems associated with manual system configuration.

To help me get unstuck from this particular viewpoint, Mathias Lafeldt offered
to demonstrate to me why infrastructure automation matters, even if you aren't
maintaining hundreds of servers or spending dozens of hours a week babysitting
production systems. To teach me this lesson, Mathias built a Chef cookbook to
completely automate the process of building an environment suitable for running
Practicing Ruby's web application, starting with nothing but a bare Ubuntu
Linux installation. The early stages of this process weren't easy: Jordan and I
found ourselves having to answer more questions about our system setup than I
ever thought would be necessary. But as things started to fall into place and
recipes started getting written, the benefits of being able to conceptualize a
system as code rather than as an amorphous blob of configuration files and
interconnected processes began to reveal themselves.

The purpose of this article is not to teach you how to get up and running with
Chef, nor is it meant to explain every last detail of the cookbook that
Mathias built for us. Instead, it will help you learn about the core concepts of
infrastructure automation the same way I did: by tearing apart a handful of real
use cases and seeing what you can understand about them. If you've never used
an automated system administration workflow before, or if you've only ever run
cookbooks that other people have provided for you, this article will give you a
much better sense of why the idea of treating "infrastructure as code" matters.
If you already know the answer to that question, you may still benefit from
looking at the problem from a beginner's mindset. In either case, we have
a ton of code to work our way through, so let's get started!

## A recipe for setting up Ruby 

Let's start taking a look at how Chef can be used 
to manage a basic Ruby installation. As you can see below, Chef
uses a pure Ruby domain-specific language for defining its recipes,
so it should be easy to read even if you've never worked with
the framework before:

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

Under the hood, a lot more is happening. Let's take a closer look at each
step to understand a bit more about how Chef recipes work.

**Installing ruby-build**

```ruby
include_recipe "ruby_build"
```

Including the default recipe from the [ruby-build cookbook](https://github.com/fnichol/chef-ruby_build/) 
in our own code takes care of installing the `ruby-build` command line utilty, 
and also handles installing a bunch of low-level packages that are required to compile Ruby 
on an Ubuntu system. But because all of that happens behind the scenes, we just need 
to make use of the `ruby_build_ruby` command this cookbook provides and the rest will be 
taken care of for us.

**Compiling and installing Ruby**

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
attributes (link), but its main purpose is the same as any configuration 
system: to keep source code as generic as possible by not hard-coding
application-specific values. By getting these values out of the
source file and into well-defined locations, it also makes it
easy to see all of our application-specific configuration 
data at once.

**Updating RubyGems**

```ruby
bash "update-rubygems" do
  code   "gem update --system"
  not_if "gem list | grep -q rubygems-update"
end
```

In this code we make use of a couple shell commands, the 
first of which is obviously responsible for updating Rubygems.
The second command is a guard that prevents the gem update
command from running more than once.

Most actions in Chef have similar logic baked into them to
make sure operations are only carried out when necessary. These 
guard clauses are handled internally whenever there is a well defined 
condition to check for, so you don't need to think about them often.
In the case of shell commands the operation is potentially arbitrary,
so a custom guard clause is necessary.

**Installing bundler**

```ruby
gem_package "bundler"
```

This command is roughly equivalent to typing `gem install bundler` on the
command line. Because we installed Ruby into `/usr/local`, it will be used as
our system Ruby, and so we can use `gem_package` without any additional
settings. More complicated system setups would involve a bit more
code than what you see above, but for our purposes we're able to keep 
things simple.

Putting all of these ideas together, we end up not just with an understanding of
how to go about installing Ruby using a Chef recipe, but also a glimpse
of a few of the benefits of treating "infrastructure as code". As we
continue to work through more complicated examples, those benefits
will become even more obvious.

## Setting up God for process monitoring

Now that we've tackled a simple example of a Chef recipe, let's work through 
a more interesting one. The following code is what we use for installing
and configuring the God process monitoring framework:

```ruby
include_recipe "practicingruby::_ruby"

gem_package "god"

directory "/etc/god" do
  owner "root"
  group "root"
  mode  "0755"
end

file "/etc/god/master.conf" do
  owner    "root"
  group    "root"
  mode     "0644"
  notifies :restart, "service[god]"

  home     = node["practicingruby"]["deploy"]["home_dir"] 
  god_file = "#{home}/current/config/delayed_job.god"

  content "God.load('#{god_file}') if File.file?('#{god_file}')"
end

cookbook_file "/etc/init/god.conf" do
  source "god.upstart"
  owner  "root"
  group  "root"
  mode   "0644"
end

service "god" do
  provider Chef::Provider::Service::Upstart
  action   [:enable, :start]
end
```

The short story about this recipe is that it handles the following tasks:

1. Installing the `god` gem.
2. Setting up some configuration files for `god`.
3. Registering `god` as a service to run at system boot.
4. Starting the `god` service as soon as the recipe is run.

But that's just the 10,000 foot view -- let's get down in the weeds a bit.

**Installing god via RubyGems**

```ruby
include_recipe "practicingruby::_ruby"

gem_package "god"
```

God is distributed via RubyGems, so we need to make sure Ruby is installed
before we can make use of it. To do this, we include the Ruby installation
recipe that was shown earlier. If the Ruby recipe hasn't run yet, it will
be executed now, but if it has already run then `include_recipe` will
do nothing at all. In either case, we can be sure that we have a
working Ruby configuration by the time the `gem_package` command is called.

The `gem_package` command itself works exactly the same way as it did when we
used it to install Bundler in the Ruby recipe, so there's nothing new to say
about it.

**Setting up a master configuration file**

```ruby
directory "/etc/god" do
  owner "root"
  group "root"
  mode  "0755"
end

file "/etc/god/master.conf" do
  owner    "root"
  group    "root"
  mode     "0644"
  notifies :restart, "service[god]"

  home     = node["practicingruby"]["deploy"]["home_dir"] 
  god_file = "#{home}/current/config/delayed_job.god"

  content "God.load('#{god_file}') if File.file?('#{god_file}')"
end
```

A master configuration file is typically used with God to load
all of the process-specific configuration files for a whole system 
when God starts up. In our case, we only have one process to watch, 
so our master configuration is a simple one-line shim that points at the
`delayed_job.god` (link) file that is deployed alongside our Rails 
application.

Because our `/etc/god/master.conf` file is so trivial, we directly specify 
its contents in the recipe itself rather than using one of Chef's more
complicated mechanisms for dealing with configuration files. In this
particular case, manually creating the file would certainly involve
less work, but we'd lose some of the benefits that Chef is providing here.

In particular, it's worth noticing that file permissions and ownership
are explicitly specified in the recipe, that the actual location
of the file is configurable, and that Chef will send a notification
to restart God whenever this file gets created. All of these things
are the sort of minor details that are easily forgotten when
manually managing configuration files on servers.

**Running god as a system service**

God needs to be running at all times, so we want to make sure that it started on
system reboot and cleanly terminated when the system is shut down. To do that, we
can configure God to run as an Upstart service. To do that, we need to start
by creating yet another configuration file:

```ruby
cookbook_file "/etc/init/god.conf" do
  source "god.upstart"
  owner  "root"
  group  "root"
  mode   "0644"
end
```

The `cookbook_file` command used here is similar to the `file` command, but has a
specialized purpose: To copy files from a cookbook's `files` directory to
some location on the system being automated. In this case, we're
using the `files/god.upstart` cookbook file as our source, and it
looks like this:

```
description "God is a monitoring framework written in Ruby"

start on runlevel [2345]
stop on runlevel [!2345]

pre-start exec god -c /etc/god/master.conf
post-stop exec god terminate
```

Here we can see exactly what commands are going to be used to start and 
shutdown God, as well as the runlevels that it will be started at
stopped on. We can also see that the `/etc/god/master.conf` file we
created earlier will be loaded by God whenever it starts up.

Now all that remains is to enable the service to run when the system
boots, and also tell it to start up right now:

```ruby
service "god" do
  provider Chef::Provider::Service::Upstart
  action   [:enable, :start]
end
```

It's worth mentioning here that if we didn't explicitly specify the
`Service::Upstart` provider, Chef would expect the service
configuration file to be written as a [System-V init
script](https://raw.github.com/elm-city-craftworks/practicing-ruby-cookbook/37ca12dc6432dfee955a70b6f2cc288e40782733/files/default/god.sh), 
which are written at a much lower level of abstraction. There
isn't anything wrong with doing things that way, but Upstart
scripts are definitely more readable. 

By this point, we've already seen how Chef can be used to install packages,
manage configuration files, run arbitrary shell commands, 
and set up system services. That knowledge alone will take you far,
but let's look at one more recipe to discover a few more 
advanced features before we wrap things up.

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
    DOM=#{domain_name}
    openssl genrsa -out $DOM.key 4096
    openssl req -new -batch -subj "/CN=$DOM" -key $DOM.key -out $DOM.csr
    openssl x509 -req -days 365 -in $DOM.csr -signkey $DOM.key -out $DOM.crt
    rm $DOM.csr
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

**Installing and configuring Nginx**

```ruby
# Override default Nginx attributes
node.set["nginx"]["worker_processes"]     = 4
node.set["nginx"]["worker_connections"]   = 768
node.set["nginx"]["default_site_enabled"] = false

# Install Nginx and set up nginx.conf
include_recipe "nginx::default"
```

**Generating SSL keys**

```ruby
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
    DOM=#{domain_name}
    openssl genrsa -out $DOM.key 4096
    openssl req -new -batch -subj "/CN=$DOM" -key $DOM.key -out $DOM.csr
    openssl x509 -req -days 365 -in $DOM.csr -signkey $DOM.key -out $DOM.crt
    rm $DOM.csr
  EOS
  notifies :reload, "service[nginx]"
  not_if   { ::File.exists?(::File.join(ssl_dir, domain_name + ".crt")) }
end
```

**Configuring Nginx to serve up Practicing Ruby**

```ruby
template "#{node["nginx"]["dir"]}/sites-available/practicingruby" do
  source "nginx_site.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables(:domain_name => domain_name)
end

nginx_site "practicingruby" do
  enable true
end
```

## Everything else



[puppet]: http://puppetlabs.com




