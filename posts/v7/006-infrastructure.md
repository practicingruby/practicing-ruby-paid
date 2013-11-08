The traditional approach to system administration work is a fundamentally 
brittle and error-prone process. The core problem is 
that managing a system by hand is roughly equivalent to hot-patching a 
running program rather than working with its source code. This makes it
very difficult to fix problems when they occur, and also makes it much
more challenging to maintain an accurate mental model of how
the system will behave with each new change.

The risks of doing system administration work manually can certainly be
mitigated somewhat through a combination of good documentation, common
conventions, regular system backups, and sufficient knowledge of the
problem domain. Even without those luxuries, the effects of system-level
failures are not always catastrophic: a few minutes of 
production downtime because of a misconfigured server setup, or a few 
hours of downtime for a single developer because of a botched system 
upgrade would probably not be considered the end of the world in most
scenarios. For many programmers, the pain caused by system administation
work is simply not significant enough to force them to search for
greener pastures.

Based on this line of reasoning, it's tempting to assume that there
wouldn't be much benefit in automating your infrastructure management 
process until you experience enough pain to justify it. However,
treating "infrastructure as code" isn't just about reducing the
cost of failures or cutting down the time you spend on tedious 
chores -- it's also about making your systems more understandable, 
flexible, and portable. These are all the kinds of things we strive for
in our code, so it makes sense to treat our infrastructure with the
same level of care.

In this article, we will make use of the Chef platform
to work our way through two small infrastructure automation projects: one that 
handles a basic Ruby installation, and another that sets up all the necessary 
underplumbing to run Practicing Ruby's web application. By the time
you're done reading, you won't be a Chef expert, but you will be
well on your way towards doing some infrastructure automation work in 
your own projects.

## Cooking up a minimal Ruby environment

TODO: Add a note mentioning that ruby_build is an external cookbook,
and maybe expand this section with a bit more detail.

The fundamental unit of organization in Chef is the recipe. A recipe defines
various resources which are used for managing some aspect of a system's
infrastructure. For example, the following code could be used to set up
a very basic Ruby environment on a system:

```ruby
include_recipe "ruby_build"

ruby_build_ruby "2.0.0-p247" do
  prefix_path "/usr/local"
end

execute "update-rubygems" do
  command "gem update --system"
  not_if  "gem list | grep -q rubygems-update"
end

gem_package "bundler"
```

When executed, this recipe does all of the following things:

1. Installs the `ruby-build` command line tool.
2. Uses `ruby-build` to compile and install Ruby 2.0 to `/usr/local`.
3. Updates Rubygems to the latest version.
4. Installs the `bundler` gem.

The main difference between this recipe and a shell script to accomplish
the same task is that it is written at a much higher level of abstraction. 
This makes it possible for the Chef platform to provide robust error handling, 
consistency checks, dependency management, and other useful features that 
would be cumbersome to implement manually in a shell script.

Even in this very basic example, we can see a tangible benefit of using 
Chef. If you were to attempt to manually install `ruby-build` on an Ubuntu 
system, you would also need to install the `git-core`, `libssl-dev`, 
and `zlib1g-dev` packages. To know that, you'd either need to find out by
trial and error or dig through the wiki page for `ruby-build` to find a 
note about these dependencies. The cookbook we used to install `ruby-build`
took care of installing these packages for us, giving us one less thing 
to think about when configuring our systems, and one less stumbling block
to trip over. 

But wherever there is a benefit, there are also costs. Unlike a shell
script which can be directly executed without any complicated setup,
Chef recipes need to be packaged up in "cookbooks" before they can do
anything useful, and some additional underplumbing is also needed
to manage the cookbooks themselves. Let's take a moment now
to briefly explore what it takes to get all those building 
blocks into place.

## Setting up Chef Solo and Vagrant for cookbook development

In many settings, Chef uses a client/server
model in which configuration data and cookbooks are stored on a server 
and then a client program is used to run recipes on whatever systems
that need to be automated. This is powerful, but also a bit complicated.
To simplify things a bit, we can make use of Chef Solo, a version of
Chef that is capable of running recipes in a standalone mode.

Recipes need to be executed in an isolated environment in order to 
meaningfully verify their behavior. This could be physical hardware
with a barebones operating system installed on it, or a cloud-based
server of some sort. However, provisioning those sorts of systems
while developing and testing recipes would be very tedious. Instead,
it makes sense to work with virtual machines running locally, 
and that's where Vagrant comes in handy.

Vagrant makes it very easy run Chef recipes within a VirtualBox VM. The basic
idea is that you provide a `Vagrantfile` in your project that tells Vagrant
which VM image you want to use, and how to go about provisioning it. The
configuration shown below configures a system to use Ubuntu 12.04 (Precise
Pangolin) and Chef Solo 11.6.2:


```ruby
VAGRANTFILE_API_VERSION="2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "precise64"

  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/precise/current/"+
                      "precise-server-cloudimg-amd64-vagrant-disk1.box"

  # NOTE: You will need to install the vagrant-omnibus plugin for this to work
  config.omnibus.chef_version = "11.6.2"

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "vendor/cookbooks"
    chef.add_recipe "demo::default"
  end
end
```

This `Vagrantfile` gets us most of the way there, but in order to make use of it
we need to do two more things: package our own recipe up in cookbook format, and
set up a way to download our external dependencies. To see how these remaining two 
chores get dealt with, take a look at the README and overall file structure for this [sample cookbook](https://github.com/elm-city-craftworks/minimal-cookbook-demo). If you've ever packaged up a Ruby gem before, 
you will notice some similarities in the conventions that Chef uses, even though its 
toolchain is a bit different than what is used in standard Ruby projects.

With all the boilerplate in place and the cookbooks installed, booting up the 
system and provisioning it for the first time is as easy as 
typing `vagrant up`. Once that is done, the virtualized system
can be directly accessed via `vagrant ssh`, which makes it
easy to test whether things worked as you expected they would.
For example, to verify that this particular recipe worked correctly,
we could run the following commands:

```
$ vagrant ssh
Welcome to Ubuntu 12.04.3 LTS (GNU/Linux 3.2.0-55-generic x86_64) ...

vagrant@vagrant-ubuntu-precise-64:~$ ruby -v
ruby 2.0.0p247 (2013-06-27 revision 41674) [x86_64-linux]

vagrant@vagrant-ubuntu-precise-64:~$ gem -v
2.1.10

vagrant@vagrant-ubuntu-precise-64:~$ bundle -v
Bundler version 1.3.
```

If you're curious about how this all works, you should be able to
reproduce the same results within your own virtual machine by
cloning the [minimal-cookbook-demo](https://github.com/elm-city-craftworks/minimal-cookbook-demo) 
repository and following the instructions in the README. The basic skeleton
provided there can also serve as a starting point for your 
own experiments, but keep in mind that it's meant to serve
as a learning example rather than a demonstration of Chef best practices.

Hopefully by this point you have a basic understanding of what Chef and Vagrant
are used for, and what the basic structure of a recipe looks like. We'll now
work our way through a much more detailed example to see how these ideas
can be put into practice.

[Vagrant]: http://www.vagrantup.com/
[VirtualBox]: https://www.virtualbox.org

## Provisioning an environment for practicingruby.com

* Subrecipes
* Attributes

Practicing Ruby's web app is built on top of a conservative software stack that
should be familiar to most Rails developers: Ubuntu Linux, Nginx, Unicorn, PostgreSQL, 
God, DelayedJob, Capistrano, Ruby 2.0, and Rails 3.2. There's nothing
particularly exciting about these choices, but they get the job done. TODO
Reorder


```ruby
include_recipe "apt::default"

# Include all the pieces
include_recipe "practicingruby::_deploy_user" 
include_recipe "practicingruby::_ruby"
include_recipe "practicingruby::_postgresql"
include_recipe "practicingruby::_nginx"
include_recipe "practicingruby::_unicorn"
include_recipe "practicingruby::_god"
include_recipe "practicingruby::_mailcatcher"
include_recipe "practicingruby::_rails"
```

`user_account`, sudo resources. Introduce concept of attributes
Consider merging w. app (rails) recipe

```ruby
# Create deploy user
user_account node["practicingruby"]["deploy"]["username"] do
  ssh_keys     node["practicingruby"]["deploy"]["ssh_keys"]
  ssh_keygen   false
end

# Configure sudo privileges
sudo node["practicingruby"]["deploy"]["username"] do
  user     node["practicingruby"]["deploy"]["username"]
  commands node["practicingruby"]["deploy"]["sudo_commands"]
  nopasswd true
end
```

Replace below with a diff

```diff
include_recipe "ruby_build"

- ruby_build_ruby "2.0.0-p247" do
+ ruby_build_ruby node["practicingruby"]["ruby"]["version"] do
  prefix_path "/usr/local"
end

execute "update-rubygems" do
  command "gem update --system"
  not_if  "gem list | grep -q rubygems-update"
end

gem_package "bundler"
```

`postgresql_database` resource. discuss what server / client do?

```ruby
# Install PostgreSQL server and client
include_recipe "postgresql::server"
include_recipe "postgresql::client"

# Make postgresql_database resource available
include_recipe "database::postgresql"

# Create database for Rails app
db = node["practicingruby"]["database"]
postgresql_database db["name"] do
  connection(
    :host     => db["host"],
    :port     => node["postgresql"]["config"]["port"],
    :username => db["username"],
    :password => db["password"],
  )
end
```

Find out why we deviate from Nginx defaults (jordan)

directory, bash, template, `nginx_site` resource

Find out difference between bash and execute

Introduce templates

```ruby
#
# Cookbook Name:: practicingruby
# Recipe:: nginx
#
# Installs and configures Nginx
#

# Override default Nginx attributes
node.set["nginx"]["worker_processes"]     = 4
node.set["nginx"]["worker_connections"]   = 768
node.set["nginx"]["default_site_enabled"] = false

# Install Nginx and set up nginx.conf
include_recipe "nginx::default"

# Create directory to store SSL files
ssl_dir = ::File.join(node["nginx"]["dir"], "ssl")
directory ssl_dir do
  owner  "root"
  group  "root"
  mode   "0600"
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
  not_if { ::File.exists?(::File.join(ssl_dir, domain_name + ".crt")) }
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

template, service resource. Learn more about service resource.
Why don't we see it in Postgres? Is it taken care of behind
the scenes for us?  Discuss upstart, too.

```ruby
#
# Cookbook Name:: practicingruby
# Recipe:: unicorn
#
# Installs upstart script for Unicorn
#

template "/etc/init/unicorn.conf" do
  source "unicorn.upstart.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables(
    :deploy_user => node["practicingruby"]["deploy"]["username"],
    :deploy_dir  => ::File.join(node["practicingruby"]["deploy"]["home_dir"], "current")
  )
end

# Unicorn is usually started by Capistrano and we only have to make sure that
# it is also started when booting.
service "unicorn" do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true
  action :enable
end
```

Why do recipes need to be repeated like below? Is it to explicitly resolve
dependencies? See template#notifies and what it does. 

`gem_package`, directory, 
`cookbook_file` (it's just a way to copy a file in place), `service`


```ruby
# Install Ruby first
include_recipe "practicingruby::_ruby"

# Install god gem
gem_package "god"

# Create config directory
directory "/etc/god" do
  owner  "root"
  group  "root"
  mode   "0755"
end

# Create config file
template "/etc/god/master.conf" do
  source   "god.conf.erb"
  owner    "root"
  group    "root"
  mode     "0644"
  notifies :restart, "service[god]"
  variables(
    :god_file => "#{node["practicingruby"]["deploy"]["home_dir"]}/current/config/delayed_job.god"
  )
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

Only uses basic incudes and execute.

```ruby
# Install Ruby first
include_recipe "practicingruby::_ruby"

# Install MailCatcher
include_recipe "mailcatcher::default"

# Start MailCatcher as mailcatcher::default doesn't do it for us
bash "start-mailcatcher" do
  code     "true"
  notifies :start, "service[mailcatcher]"
  not_if   "pgrep mailcatcher"
end
```

package, directory, template (Note that rails misnomer, it's really just a
deploy setup -- consider merge!), discuss the use of .env

```ruby

# Install JavaScript runtime for Rails app
package "nodejs"

# Install Pygments for syntax highlighting
package "python-pygments"

# Create deploy user first
include_recipe "practicingruby::_deploy_user"

# Create shared directory that will be used by Capistrano
shared_dir = ::File.join(node["practicingruby"]["deploy"]["home_dir"], "shared")
directory shared_dir do
  owner  node["practicingruby"]["deploy"]["username"]
  group  node["practicingruby"]["deploy"]["username"]
  mode   "2775"
end

# Create environment configuration
template ::File.join(shared_dir, ".env") do
  source "env.sh.erb"
  owner  node["practicingruby"]["deploy"]["username"]
  group  node["practicingruby"]["deploy"]["username"]
  mode   "0644"
  variables(:rails => node["practicingruby"]["rails"])
end

# Create database configuration
template ::File.join(shared_dir, "database.yml") do
  owner  node["practicingruby"]["deploy"]["username"]
  group  node["practicingruby"]["deploy"]["username"]
  mode   "0644"
  variables(:db => node["practicingruby"]["database"])
end
```

---

We've never had a strong urge to reduce Practicing Ruby's system
administration overhead, because the slow pace of our development and relatively 
low complexity of the application itself have never caused us enough pain to 
justify learning a whole new way of doing things. But when Mathias
volunteered to build a Chef cookbook for us, we were excited to
take him up on the offer. As Mathias began his work, Jordan and I quickly 
realized two things:

1) That I knew next-to-nothing about Practicing Ruby's production environment.
Pretty much everything below the Rails layer was pure magic to me, because I
never needed to touch it. This made me very dependent on Jordan for our
sysadmin work, but because we almost never experienced infrastructure-level
failures it wasn't much of a concern for us.

2) The configuration data in our system was scattered all over the place.
Jordan could easily answer questions about how things were set up when asked for
a specific piece of information, but we didn't have anything even closely resembling 
a roadmap of where everything was and how it all came together. This made building 
a fresh system from scratch very difficult if you didn't have specialized 
knowledge about our setup.

These insights are not especially profound, but I still count them as the first
benefit we got from attempting to automate our infrastructure. The two problems
listed above tend to feed into each other, and easily arise in circumstances
where one person becomes an information silo to save another from having to
spend time learning something. If writing a Chef cookbook could help us break
down those walls, that would be a win in itself.



## Discuss Capistrono deployment, ssh config, hosts setting, etc. 

## Walk through use cases / caveats

## Dev improvements: developer mode, mailcatcher, dotenv, foreman

## Wrapup


----

## Intro (probably rewrite to frame the story differently / more concretely)

In an ideal world, setting up any software system would not require any
complicated work at all. You'd just run a script, go grab yourself a coffee, and
then by the time you got back you'd have a working system up and running. Down
the line when your infrastructure changes, someone would tweak
that script, and then you'd repeat the same process to quickly migrate to an
updated system. In theory, that's how a well-managed software system ought to
work.

In practice, many projects don't come anywhere close to that ideal. Development
environments can be extremely painful to set up without lengthy conversations with
existing maintainers, and production environments are often maintained by a
single person who can easily become the bottleneck whenever something goes
wrong. Even if we have an easy deployment workflow, we often know little about
the magic that runs behind the scenes to get our code up and running in
production unless we wrote the deploy script ourselves.

We let things get bad like this because the vast majority of our
painful experiences happen incrementally. A new dependency with a complex setup
might get added mid-way through a project, and everyone will feel irritated for
a day until things get sorted out. As soon as everyone has their systems back
in working order, the pain goes away and is promptly forgotten about . But as this process is repeated over and over again, it becomes more and more difficult to provision a system from scratch, particularly if not much documentation was written at each step along the way. This is how information silos develop, and its also how we
end up way over our heads in even relatively simple software projects.

In recent years, awareness of these sort of problems has given rise to a
DevOps-oriented mindset in some projects and organizations. Although DevOps
covers a lot of different concepts, one cornerstone is that robust 
infrastructure automation is key to getting us out of this particular tarpit.
If we can treat our infrastructure as we do our code, we're able to version it,
incrementally improve it, share reusable bits of process with each other, and
most importantly explictly specify all the moving parts that make up our systems.

In this article, I will show you how Mathias Lafeldt built a Chef
cookbook that takes a bare Ubuntu system and configures all the necessary
infrastructure to run Practicing Ruby's web application -- suitable for running
under virtualization via Vagrant, or in the cloud on Amazon EC2. This example is
particularly interesting because we never considered using a systems automation
framework when we built this web app. Building a cookbook years after the system
was already in production shows us that these techniques can be applied to existing systems and not just greenfield applications.

### What is the workflow like when developing a chef cookbook?

To automate an application's infrastructure, you build a cookbook made up of
recipes that install, configure and manage all of the dependencies your
application relies on.

Cookbooks are typically built on top of lower-level resources, some of
which are provided by Chef itself, and others are provided by third-party
cookbooks that were written by other Chef users.

Recipes are configurable via Chef's attribute system, and also can use ERB
templates to generate whatever configuration files a system needs.

When you provision a system, recipes only run if they haven't already
successfully completed, and Chef will pick up where it left off whenever there
is a falure.

http://mlafeldt.github.io/blog/2012/09/learning-chef/
http://docs.opscode.com/essentials_cookbook_recipes.html
http://docs.opscode.com/resource.html

Things like external dependencies, supported platforms, included recipes, etc.
are specified in `metadata.rb`.

## What are the main differences between automated infrastructure and manually configured systems?

On a manually configured system, you typically will run commands and edit files
to install and configure software once. You might write some documentation, but
there is no way to verify it without keying everything in manually on a new
system. You may also script some parts of the process, but those scripts will
not necessarily be particularly fault tolerant, and failures can leave the
system in an inconsistent state. Unless you are very familiar with the platform
you're administering, finding all the relevant configuration files and figuring
out what programs need to be running can be challenging. If the system is
suddenly wiped out or you need to provision a new one, doing so can be quite
challenging

In an automated infrastructure, the running system is essentially the end result
of a code-based process that is explicitly specified. Because automated
infrastructure relies on nothing more than source code for cookbooks and bare
metal resources (such as a base Ubuntu server installation), the system itself
is not administered directly but managed through a configuration management
system (i.e. Chef). If something goes wrong or a new system needs to be
provisioned, it is very easy to do this in a relaible way, since the whole
system is designed to be formally specified from scratch.

There is of course overhead in managing all the automations (and getting their
prerequisites set up), but the gain is a much more robust and repeatable
process. Other costs of automation include the learning curve: you need to know
a bit about the systems you are configuring to use cookbooks, but you also need
to know about how cookbooks work, too (they're leaky abstractions). There is
also the "build-borrow-or-steal" issue common to all open-source, in which you
may need to evaluate several cookbooks before finding one that meets your needs,
and in the worst case you may need to write one yourself. But this is no
different than reading information spread around the web when it comes to manual
configurations.

## What are typical use cases / benefits for infrastructure automation

Tons of them!


### Practicing Ruby's infrastructure

* Ruby
* Python (for syntax highlighting)
* Javascript (for Rails)
* Build-essential (C compiler, headers, etc)
* 

---


Establish tedium/brittleness of manual system provisioning
We're building a slightly modified version of a production environment
suitable for experimenting with various system configuration and debugging
*most* production issues.

Common uses:
- production systems deployable directly from Chef
- turnkey development environments
- architectural testbeds

(we're *sort of* in the third category)

Chef/Vagrant offer similar promises and costs as something like Rails,
lets you focus on much higher level problems, but involves learning
a whole new environment and plying by its rules.

Having *a* formal system in place seems like its valuable on its own even
without considering the specific benefits that system offers. Because it forces
you to be explicit, invites questions about efficiency/best practices, and gives
a standard set of concepts for communicating with others.

I have not been that involved with Practicing Ruby's system administration, so
it was fun for me to finally see the whole stack specified.

--------------------------------------------------------------------

What is the quickest win I can give the reader?

"After installing a couple packages (VirtualBox and Vagrant), it is possible to
get an entire Ubuntu system from zero to having everything you need to run
practicing-ruby-web by typing just the following commands"


I don't assume the reader is familiar with Chef/Vagrant except
maybe having a vague idea that it's a system automation platform.

I don't want to offer a tutorial as much as a conceptual
understanding of what "infrastructure as code" can look like,
in the context of a semi-realistic example.

By the end of the article, I want the reader to know how
the various parts (Virtualbox, Vagrant, Vagrant-omnibus, 
Chef recipes, attributes, templates, and Berkshelf) all fit together.

I want them to notice the similarities and differences between
typical Ruby programming (tools + practices) and Chef programming.

I want the reader to be able to understand most of the Practicing Ruby cookbook,
at least well enough to:

1) Provision a running copy of the app themselves
2) Use the code as an example for provisioning their own systems to 
experiment with.

I don't expect that someone will be able to immediately take the knowledge from
this article and go out to do serious devops work. But I do want them to get far
enough to be able to experiment while reading documentation, resources, etc.


---------------------------------------------------------------

Outside-in approach:

1. Vagrantfile
2. Berksfile / metadata.rb
3. Attributes / chef.json
4. Recipes
5. Templates



---------------------------------------------------------------

## VirtualBox: 

A free virtualization system, which lets you run
nearly any flavor of Linux within a virtual machine. Although
it has a full GUI and is suitable for running desktop enviornments,
we use it only as an internal dependency via Vagrant.

## Vagrant:

A system that makes it easy to describe what kind of VM you want
to build, and what specs it should have (memory, # cpus, etc).

Vagrant also handle provisioning, starting, and stopping a
virtual box from the command line. By making use of a 
`Vagrantfile`, projects can provide a preconfigured setup
for developers. In some cases, this makes it possible to
get a virtualized environment up and running for a project
by simply typing `vagrant up`.

Vagrant also handles things like making it easy to SSH into
the virtual box (`vagrant ssh`), handling networking between multiple 
boxes as well as the host environment, and also synchronizing
shared folders between the host machine and shared environment.
It even shares the project folder which contains the `Vagrantfile`
by default!

Vagrant supports the use of a *provisioner* to do complex configuration
tasks inside the virtual machine. This can be as simple as writing
some shell scripts, but can also support more robust frameworks like
Puppet and Chef.

Vagrant also supports a plugin architecture that allows you to extend its
functionality.

Finally Vagrant makes it trivial to package up a "box" for use with VirtualBox.

## Chef

Infrastructure automation software that handles installation, configuration,
and execution of an entire system. The main goal is to turn "infrastructure 
into code", with all the associated flexibility and reusability that implies.

In production environments, chef uses a client/server model to make it easy
to scale across hardware and VMs. For development and experimental purposes,
chef solo allows you to make use of Chef without a server setup.

Chef's fundamental unit of organization is the "cookbook", which is made up of
various "recipes" that handle some aspect of system management.

Recipes are coded up in a Ruby DSL, and also can support file generation via ERB
templates. There is also a built in configurable attribute system, which can be managed
in a defaults file but also overridden on a per-user basis.

Recipes can also include other recipes, configuring some settings and then
reusing various bits of functionality.

Chef also handles workflow management things, such as ensuring that failed
recipes can be retried, and is capable of picking up where it left off 
upon failure. This makes the feedback loop a little bit faster
while developing a cookbook, because you don't usually need to do 
a whole build from scratch when you encounter an error. 

Chef is a special purpose environment, and its not assumed that its users will
be strong Ruby programmers.

(note duplication like `default["a"]["b"]["c"]` as convention)

(EXPAND ON ALL THE RECIPES WE USE, AND ON HOW EACH SUBSYSTYEM WORKS
-- REREAD MATHIAS AND ALSO THE OPSCODE DOCS)

## Vagrant-omnibus




Unsure what this is used for, discuss w. Mathias.
Is it basically a version manager / installer for Chef (i.e. RVM for chef?)

https://github.com/schisamo/vagrant-omnibus


## Berkshelf

This is essentially Bundler for Chef. It allows you to manage cookbook
dependencies and their versions. Similar to how you can tell bundler to read its
dependencies from the standard gemspec file, you can tell Berkshelf to read
from Chef's stanbdard metadata.rb file, and that's what we do:

https://github.com/elm-city-craftworks/practicing-ruby-cookbook/blob/master/metadata.rb

## Capistrano

Chef can be used directly for deployment, without the need for Capistrano. But
because we are focusing on simply creating a simulation of our production
environment that we can run in isolation (and not actually using Chef in
production), we use a custom environment that allows us to "deploy" to our
vagrant-managed box via Capistrano. This is very simple stuff, since the box is
readily accessible via SSH, and generally similar in configuration to our
production environment.

-------------

Show how to use Vagrant + Chef to set up ubuntu with chruby,
Ruby 2.0, and JRuby? (Or some other smallish example)

Discuss Practicing Ruby's dependencies (in development and in production)

  - Ubuntu
  - NodeJS
  - Ruby (via Chruby)
  - Python
  - Nginx (with SSL) + Unicorn
  - PostgreSQL
  - Delayed Job (Email delivery, cache warming, etc.)
  - God
  - Whenever
  - Service Deps: Mailchimp, Mixpanel, Github, Stripe, Sendgrid
 
Show how to automate Practicing Ruby's stack. (Maybe not comprehensive, only
point out where different things are used)

Note how it was interesting that setting up Chef required us to be *much* more
specific about our infrastructure, everything was previously no better than
"works-for-me". Also shows where our brittle pieces were (i.e. initializers and
a generally brittle dev environment). In our conversations, we kept coming back
to these kinds of things, which is eventually what lead us to add dotenv,
foreman, mailcatcher, etc.

Discuss the costs and benefits of working with Chef/Vagrant
(and the limitations of our current approach)

- https://github.com/opscode-cookbooks/postgresql#chef-solo-note

Potential resources for later:

- http://railscasts.com/episodes/292-virtual-machines-with-vagrant?view=asciicast
- http://12factor.net/

## Walk through the full PR environment

* Describe that what we're building is production-ish,
but not a literal copy (and WHY).
* List out each recipe
* Show full recipes for new concepts, abridge wherever possible

## Discuss Capistrono deployment, ssh config, hosts setting, etc. 

## Walk through use cases / caveats

## Dev improvements: developer mode, mailcatcher, dotenv, foreman

## Wrapup

----

## Intro (probably rewrite to frame the story differently / more concretely)

In an ideal world, setting up any software system would not require any
complicated work at all. You'd just run a script, go grab yourself a coffee, and
then by the time you got back you'd have a working system up and running. Down
the line when your infrastructure changes, someone would tweak
that script, and then you'd repeat the same process to quickly migrate to an
updated system. In theory, that's how a well-managed software system ought to
work.

In practice, many projects don't come anywhere close to that ideal. Development
environments can be extremely painful to set up without lengthy conversations with
existing maintainers, and production environments are often maintained by a
single person who can easily become the bottleneck whenever something goes
wrong. Even if we have an easy deployment workflow, we often know little about
the magic that runs behind the scenes to get our code up and running in
production unless we wrote the deploy script ourselves.

We let things get bad like this because the vast majority of our
painful experiences happen incrementally. A new dependency with a complex setup
might get added mid-way through a project, and everyone will feel irritated for
a day until things get sorted out. As soon as everyone has their systems back
in working order, the pain goes away and is promptly forgotten about . But as this process is repeated over and over again, it becomes more and more difficult to provision a system from scratch, particularly if not much documentation was written at each step along the way. This is how information silos develop, and its also how we
end up way over our heads in even relatively simple software projects.

In recent years, awareness of these sort of problems has given rise to a
DevOps-oriented mindset in some projects and organizations. Although DevOps
covers a lot of different concepts, one cornerstone is that robust 
infrastructure automation is key to getting us out of this particular tarpit.
If we can treat our infrastructure as we do our code, we're able to version it,
incrementally improve it, share reusable bits of process with each other, and
most importantly explictly specify all the moving parts that make up our systems.

In this article, I will show you how Mathias Lafeldt built a Chef
cookbook that takes a bare Ubuntu system and configures all the necessary
infrastructure to run Practicing Ruby's web application -- suitable for running
under virtualization via Vagrant, or in the cloud on Amazon EC2. This example is
particularly interesting because we never considered using a systems automation
framework when we built this web app. Building a cookbook years after the system
was already in production shows us that these techniques can be applied to existing systems and not just greenfield applications.

### What is the workflow like when developing a chef cookbook?

To automate an application's infrastructure, you build a cookbook made up of
recipes that install, configure and manage all of the dependencies your
application relies on.

Cookbooks are typically built on top of lower-level resources, some of
which are provided by Chef itself, and others are provided by third-party
cookbooks that were written by other Chef users.

Recipes are configurable via Chef's attribute system, and also can use ERB
templates to generate whatever configuration files a system needs.

When you provision a system, recipes only run if they haven't already
successfully completed, and Chef will pick up where it left off whenever there
is a falure.

http://mlafeldt.github.io/blog/2012/09/learning-chef/
http://docs.opscode.com/essentials_cookbook_recipes.html
http://docs.opscode.com/resource.html

Things like external dependencies, supported platforms, included recipes, etc.
are specified in `metadata.rb`.

## What are the main differences between automated infrastructure and manually configured systems?

On a manually configured system, you typically will run commands and edit files
to install and configure software once. You might write some documentation, but
there is no way to verify it without keying everything in manually on a new
system. You may also script some parts of the process, but those scripts will
not necessarily be particularly fault tolerant, and failures can leave the
system in an inconsistent state. Unless you are very familiar with the platform
you're administering, finding all the relevant configuration files and figuring
out what programs need to be running can be challenging. If the system is
suddenly wiped out or you need to provision a new one, doing so can be quite
challenging

In an automated infrastructure, the running system is essentially the end result
of a code-based process that is explicitly specified. Because automated
infrastructure relies on nothing more than source code for cookbooks and bare
metal resources (such as a base Ubuntu server installation), the system itself
is not administered directly but managed through a configuration management
system (i.e. Chef). If something goes wrong or a new system needs to be
provisioned, it is very easy to do this in a relaible way, since the whole
system is designed to be formally specified from scratch.

There is of course overhead in managing all the automations (and getting their
prerequisites set up), but the gain is a much more robust and repeatable
process. Other costs of automation include the learning curve: you need to know
a bit about the systems you are configuring to use cookbooks, but you also need
to know about how cookbooks work, too (they're leaky abstractions). There is
also the "build-borrow-or-steal" issue common to all open-source, in which you
may need to evaluate several cookbooks before finding one that meets your needs,
and in the worst case you may need to write one yourself. But this is no
different than reading information spread around the web when it comes to manual
configurations.

## What are typical use cases / benefits for infrastructure automation

Tons of them!

* Provisioning and scaling production systems
* Building turn-key development environments for complex applications
  (simple ones may not be worth the overhead)
* Experimenting with platform and network configurations under virtualization
  and with no risk of breaking "real" systems
* Building end-to-end testing environments
* Managing the complexity of decoupling a system into many independent services.
* Reducing institutionalized knowledge while improving process reuse / standardization.
* Making systems easier to evolve / change over time.

### Practicing Ruby's infrastructure

* Ruby
* Python (for syntax highlighting)
* Javascript (for Rails)
* Build-essential (C compiler, headers, etc)
* 

---


Establish tedium/brittleness of manual system provisioning
We're building a slightly modified version of a production environment
suitable for experimenting with various system configuration and debugging
*most* production issues.

Common uses:
- production systems deployable directly from Chef
- turnkey development environments
- architectural testbeds

(we're *sort of* in the third category)

Chef/Vagrant offer similar promises and costs as something like Rails,
lets you focus on much higher level problems, but involves learning
a whole new environment and plying by its rules.

Having *a* formal system in place seems like its valuable on its own even
without considering the specific benefits that system offers. Because it forces
you to be explicit, invites questions about efficiency/best practices, and gives
a standard set of concepts for communicating with others.

I have not been that involved with Practicing Ruby's system administration, so
it was fun for me to finally see the whole stack specified.

--------------------------------------------------------------------

What is the quickest win I can give the reader?

"After installing a couple packages (VirtualBox and Vagrant), it is possible to
get an entire Ubuntu system from zero to having everything you need to run
practicing-ruby-web by typing just the following commands"


I don't assume the reader is familiar with Chef/Vagrant except
maybe having a vague idea that it's a system automation platform.

I don't want to offer a tutorial as much as a conceptual
understanding of what "infrastructure as code" can look like,
in the context of a semi-realistic example.

By the end of the article, I want the reader to know how
the various parts (Virtualbox, Vagrant, Vagrant-omnibus, 
Chef recipes, attributes, templates, and Berkshelf) all fit together.

I want them to notice the similarities and differences between
typical Ruby programming (tools + practices) and Chef programming.

I want the reader to be able to understand most of the Practicing Ruby cookbook,
at least well enough to:

1) Provision a running copy of the app themselves
2) Use the code as an example for provisioning their own systems to 
experiment with.

I don't expect that someone will be able to immediately take the knowledge from
this article and go out to do serious devops work. But I do want them to get far
enough to be able to experiment while reading documentation, resources, etc.


---------------------------------------------------------------

Outside-in approach:

1. Vagrantfile
2. Berksfile / metadata.rb
3. Attributes / chef.json
4. Recipes
5. Templates



---------------------------------------------------------------

## VirtualBox: 

A free virtualization system, which lets you run
nearly any flavor of Linux within a virtual machine. Although
it has a full GUI and is suitable for running desktop enviornments,
we use it only as an internal dependency via Vagrant.

## Vagrant:

A system that makes it easy to describe what kind of VM you want
to build, and what specs it should have (memory, # cpus, etc).

Vagrant also handle provisioning, starting, and stopping a
virtual box from the command line. By making use of a 
`Vagrantfile`, projects can provide a preconfigured setup
for developers. In some cases, this makes it possible to
get a virtualized environment up and running for a project
by simply typing `vagrant up`.

Vagrant also handles things like making it easy to SSH into
the virtual box (`vagrant ssh`), handling networking between multiple 
boxes as well as the host environment, and also synchronizing
shared folders between the host machine and shared environment.
It even shares the project folder which contains the `Vagrantfile`
by default!

Vagrant supports the use of a *provisioner* to do complex configuration
tasks inside the virtual machine. This can be as simple as writing
some shell scripts, but can also support more robust frameworks like
Puppet and Chef.

Vagrant also supports a plugin architecture that allows you to extend its
functionality.

Finally Vagrant makes it trivial to package up a "box" for use with VirtualBox.

## Chef

Infrastructure automation software that handles installation, configuration,
and execution of an entire system. The main goal is to turn "infrastructure 
into code", with all the associated flexibility and reusability that implies.

In production environments, chef uses a client/server model to make it easy
to scale across hardware and VMs. For development and experimental purposes,
chef solo allows you to make use of Chef without a server setup.

Chef's fundamental unit of organization is the "cookbook", which is made up of
various "recipes" that handle some aspect of system management.

Recipes are coded up in a Ruby DSL, and also can support file generation via ERB
templates. There is also a built in configurable attribute system, which can be managed
in a defaults file but also overridden on a per-user basis.

Recipes can also include other recipes, configuring some settings and then
reusing various bits of functionality.

Chef also handles workflow management things, such as ensuring that failed
recipes can be retried, and is capable of picking up where it left off 
upon failure. This makes the feedback loop a little bit faster
while developing a cookbook, because you don't usually need to do 
a whole build from scratch when you encounter an error. 

Chef is a special purpose environment, and its not assumed that its users will
be strong Ruby programmers.

(note duplication like `default["a"]["b"]["c"]` as convention)

(EXPAND ON ALL THE RECIPES WE USE, AND ON HOW EACH SUBSYSTYEM WORKS
-- REREAD MATHIAS AND ALSO THE OPSCODE DOCS)

## Vagrant-omnibus




Unsure what this is used for, discuss w. Mathias.
Is it basically a version manager / installer for Chef (i.e. RVM for chef?)

https://github.com/schisamo/vagrant-omnibus


## Berkshelf

This is essentially Bundler for Chef. It allows you to manage cookbook
dependencies and their versions. Similar to how you can tell bundler to read its
dependencies from the standard gemspec file, you can tell Berkshelf to read
from Chef's stanbdard metadata.rb file, and that's what we do:

https://github.com/elm-city-craftworks/practicing-ruby-cookbook/blob/master/metadata.rb

## Capistrano

Chef can be used directly for deployment, without the need for Capistrano. But
because we are focusing on simply creating a simulation of our production
environment that we can run in isolation (and not actually using Chef in
production), we use a custom environment that allows us to "deploy" to our
vagrant-managed box via Capistrano. This is very simple stuff, since the box is
readily accessible via SSH, and generally similar in configuration to our
production environment.

-------------

Show how to use Vagrant + Chef to set up ubuntu with chruby,
Ruby 2.0, and JRuby? (Or some other smallish example)

Discuss Practicing Ruby's dependencies (in development and in production)

  - Ubuntu
  - NodeJS
  - Ruby (via Chruby)
  - Python
  - Nginx (with SSL) + Unicorn
  - PostgreSQL
  - Delayed Job (Email delivery, cache warming, etc.)
  - God
  - Whenever
  - Service Deps: Mailchimp, Mixpanel, Github, Stripe, Sendgrid
 
Show how to automate Practicing Ruby's stack. (Maybe not comprehensive, only
point out where different things are used)

Note how it was interesting that setting up Chef required us to be *much* more
specific about our infrastructure, everything was previously no better than
"works-for-me". Also shows where our brittle pieces were (i.e. initializers and
a generally brittle dev environment). In our conversations, we kept coming back
to these kinds of things, which is eventually what lead us to add dotenv,
foreman, mailcatcher, etc.

Discuss the costs and benefits of working with Chef/Vagrant
(and the limitations of our current approach)

- https://github.com/opscode-cookbooks/postgresql#chef-solo-note

Potential resources for later:

- http://railscasts.com/episodes/292-virtual-machines-with-vagrant?view=asciicast
- http://12factor.net/
