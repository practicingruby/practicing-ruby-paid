## Introduce the concept of automated infrastructure

## Getting a base system up and running 

The production environment for practicingruby.com is a 768 MB VPS running Ubuntu
Linux 12.04.3 ("Precise Pangolin"). Using a combination of [Vagrant][] 
and [VirtualBox][], it is easy to replicate a similar environment under
virtualization that can run pretty much anywhere.

With those two tools installed, all that is needed is a `Vagrantfile` that
specifies which VM image to use for the base operating system, along with a
few configuration options:

```ruby
VAGRANTFILE_API_VERSION="2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "precise64"

  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/precise/current/"+
                      "precise-server-cloudimg-amd64-vagrant-disk1.box"

  # Mirror specs of production environment
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--memory", 768]
    v.customize ["modifyvm", :id, "--cpus", 1]
  end
end
```

Running `vagrant up` in the same directory as this file will download the base
OS image if it isn't already present on your machine, and then fire up a
VirtualBox VM running Ubuntu Linux. Without the need to do any special
configuration, you can run `vagrant ssh` to log into the box as soon as 
it boots up.

Once inside the virtual machine, you'll find that the folder containing the
`Vagrantfile` on your host machine has automatically been mapped to `/vagrant`.
This facilitates passing files back and forth between your host system and the
virtualized environment.

At this point, we have our base system in place, and we're ready
to begin working on some infrastructure automation code. Rather than jumping
into the whole process of setting up Practicing Ruby web, we'll start with a
more simple example to help you get a feel for things. (REWORD!)

[Vagrant]: http://www.vagrantup.com/
[VirtualBox]: https://www.virtualbox.org

## Cooking up a minimal Ruby environment

Of the various open-source infrastructure automation tools, Chef is among the
most widely supported systems available. It is a good option for Ruby
programmers, because its entire DSL is written in Ruby and many of its
conventions overlap with standard Ruby practices. For those reasons,
we decided to make use of Chef for our infrastructure automation work (reword!).

The fundamental unit of organization in Chef is the recipe. A recipe defines
various resources which are used for managing some aspect of a system's
infrastructure. Even if you've never seen a Chef recipe before, you should
be able to get a basic idea of how they are used by looking at the 
following example:

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

In other words, what we have here is an automated means of setting up a
barebones Ruby environment. The recipe itself isn't that much more or less
code than what it would take to run the equivalent shell commands manually, 
but it is written at a much higher level of abstraction. As a result, the
Chef code can bake in robust error handling, consistency checks,
dependency management, and other useful features that would be cumbersome
to implement manually in a shell script.

The difference between the two approaches may seem marginal at first glance,
but even in this very basic example, we can see a tangible benefit of using 
Chef. If you were to attempt to manually install `ruby_build` on an Ubuntu 
system, you would also need to install the `git-core`, `libssl-dev`, 
and `zlib1g-dev` packages. To know that, you'd either need to find out by
trial and error or dig through the wiki page for `ruby_build` to find a 
note about these dependencies. The cookbook we used to install `ruby_build`
took care of installing these packages for us, giving us one less thing 
to think about when configuring our systems, and one less stumbling block
to trip over. 

But as is typical with any very high level system, there are some costs
associated with getting Chef's underplumbing in place. In particular, the
following chores are part of getting up and running with Chef and Vagrant:

* Vagrant needs to be configured to use Chef as its provisioner. 
* Chef needs to be installed into the Vagrant box.
* External cookbooks need to be downloaded and installed.
* Various bits of metadata about the cookbook need to be specified.

In a very similar fashion to packaging up a Ruby gem or configuring a Rails
application for the first time, these chores are tedious but the workflow is
similar across projects, and the work only needs to be done once per project.
For that reason, its not terribly important for you to understand every
last detail about configuring Chef and Vagrant right now. But if you
feel like it would be cheating to skip over the boilerplate, check out this
[sample cookbook](https://github.com/elm-city-craftworks/practicing-ruby-examples/tree/master/v7/006/minimal-cookbook-demo)
and try to make some sense of it before moving on.

## Provising a complete Rails environment

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
