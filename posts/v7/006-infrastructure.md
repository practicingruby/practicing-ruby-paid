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
