The main challenge of object-oriented programming lies not in building
objects, but in understanding and defining their relationships to
each other and to the outside world. Object-oriented programming
promises to help us produce software that is resilient and easy to 
change, but these benefits can only be realized when the integration points
between objects are allowed to take center stage in design discussions.

The challenge of sensibly connecting a set of objects together to perform a
complex task is one that confounds beginner and experienced programmers 
alike. The question of how to put instances of information-hiding, 
single-responsibility-discharging, message-passing classes in touch 
with one another is hard to answer. In fact, it is hard to even 
reason about it without getting trapped by analysis paralysis. This 
explains why so many of us who are otherwise decent programmers 
struggle with this particular aspect of object-oriented programming. 

But like so many other problems we encounter in our work, this one can
be simplified greatly by introducing a common vocabulary and some rough
heuristics that make thinking and communicating about our code easier.
For reasoning about this particular design challenge, the 
"Object Peer Stereotypes" described in [Growing Object Oriented Software, Guided
by Tests][GOOS] give us some very useful conceptual tools 
to work with.

In this article, we will explore the three stereotypical relationships 
between an object and its peers that were described in GOOS: 
dependencies, notifications, and adjustments. Taken together, these 
rough categorizations do a good job of identifying the kinds of
connections that exist between objects, and that makes it easier
to develop a more nuanced view of how they communicate with 
one another. Let's start learning how to spot them!

## Dependencies

> Services that the object requires from its peers so it can perform its
> responsibilities. The object cannot function without these services. It should
> not be possible to create the object without them -- GOOS (52)

We commonly think of dependencies as being third-party libraries or
services, but all non-trivial projects also have internal dependencies. 
Whether they are internal or external, dependency relationships need to be
explicitly defined and carefully managed in order to prevent brittleness.

Alistair Cockburn's [ports and adapters][ports-and-adapters] pattern provides
one way of dealing with this problem: define interfaces in the application's
domain language that covers slices of functionality (ports), and then build 
implementation-specific objects which implement those interfaces (adapters).
This allows dependencies to be reasoned about at a higher level of abstraction,
and makes it so that systems can change more easily.

We applied this pattern (albeit without recognizing it by name) when thinking
through how Newman should handle its email dependency. We knew from the outset
that we'd need to support some sort of test mailer, and that it should be a
drop-in replacement for its real mailer. We also anticipated that down the line
we may want to support delivery mechanisms other than the `mail` gem, and
figured that some sort of adapter-based approach would be a good fit.

* Describe the protocol here
* Show at least a method or two for each mailer
* SHow some in use examples.



> Encapsulation: Ensures that the behavior of an object can only be
affected through its API. It lets us control how much a change to one
object will impact other parts of the system by ensuring that there
are no unexpected dependencies between unrelated component

* Stripe payments
* Generic payment gateway

## Notifications

> Peers that need to be kept up to date with the object’s activity. The object
> will notify interested peers whenever it changes state or performs a
> significant action. Notifications are ‘fire and forget’; the object neither
> knows nor cares which peers are listening -- GOOS (52)

Because Ruby is a message-oriented programming language, it is easy to model
many kinds of object relationships as notifications. Doing so greatly reduces
the coupling between objects, and helps establish a straight-line flow from a 
system's inputs to its outputs.

Notification-based modeling is especially useful when designing framework code,
because it is important for frameworks to know as little as possible about the
applications that are built on top of them. The following example shows a
general pattern popularized by the [rack web server interface][rack], but in
the context of an email-based system. Without getting bogged down in the
details, try to think through what happens when the 
`Newman::Server#tick` method is called: 

```ruby
module Newman
  class Server
    # NOTE: the mailer, apps, logger, and settings dependencies
    # are initialized when a Server instance is instantiated

    def tick
      mailer.messages.each do |request|
        response = mailer.new_message(:to   => request.from,
                                      :from => settings.service.default_sender)

        process_request(request, response) && response.deliver
      end

      # ... error handling code omitted
    end


    def process_request(request, response)
      apps.each do |app|
        app.call(:request  => request,
                 :response => response,
                 :settings => settings,
                 :logger   => logger)
      end

      return true

      # ... error handling code omitted
    end
  end
end
```

Did you figure it out? Let's walk through the process step by step now to
confirm:

1. The `tick` method walks over each incoming message currently queued up by the
`mailer` object (i.e. the request)

2. A placeholder `response` message is constructed, addressed to the sender of
the request.

3. The `process_request` method is called, which iterates over a
collection, executing the `call` method on each element and passing along
several dependencies that can be used to finish building a meaningful
response message.

4. Once `process_request` completes successfully, the response is delivered.
the `request`, `response`, `settings`, and `logger` objects.

Because `Newman::Server` has a notification-based relationship with its
`apps` collection, it does not know or care about the structure of those
objects. In fact, the contract is so simple that a trivial `Proc` object 
can serve as a fully functioning callback:

```ruby
Greeter = ->(params) { |params| params[:response].subject = "Hello World!" }

server.apps = [Greeter]
server.tick
```

If we wanted to make things a bit more interesting, we could add request
and response logging into the mix, using Newman's built in features:

```ruby
Greeter = ->(params) { |params| params[:response].subject = "Hello World!" }

server.apps = [Newman::RequestLogger, Greeter, Newman::ResponseLogger]
server.tick
```

These objects make use of a mixin that simplifies email logging, but as you can
see from the following code, they have no knowledge of the `Newman::Server`
object and rely entirely on the parameters being passed into their `#call`
method:

```ruby
module Newman
  class << (RequestLogger = Object.new)
    include EmailLogger

    def call(params)
      log_email(params[:logger], "REQUEST", params[:request]) 
    end
  end

  class << (ResponseLogger = Object.new)
    include EmailLogger

    def call(params)
      log_email(params[:logger], "RESPONSE", params[:response])
    end
  end
end
```

Taken together, these four objects combined form a cohesive workflow:

1. The server receives incoming emails and passes them on to its `apps` for
processing, along with a placeholder `response` object.

2. The request logger inspects the incoming email and records debugging 
information.

3. The greeter sets the subject of the outgoing response to "Hello World".

4. The response logger inspects the outgoing email and records debugging
information.

5. The server sends the response email.

The remarkable thing is not this semi-mundane process, but that the
objects involved knows virtually nothing about they collaborators, nor
are they aware of their position in the sequence of events. Context-independence
 is a powerful thing, because it allows each object to be reasoned
about, tested, and developed in isolation.

The implications of notification-based modeling extend far beyond
context-independence, but it wouldn't be easy to summarize them in 
a few short sentences. Fortunately, this topic has been covered 
extensively in other Practicing Ruby articles, particularly in 
[Issue 4.11][pr-4.11] and [Issue 5.2][pr-5.2]. Be sure to
read those articles if you haven't already; they are among the finest in our
collection.

## Adjustments

> Peers that adjust the object’s behavior to the wider needs of the system. This
includes policy objects that make decisions on the object’s behalf...and
component parts of the object if it’s a composite -- GOOS (52)

* The job of an adjustment is to shoehorn some data / functionality into the
form required by some other object.

* Adjustments can be initialized to use sensible defaults where appropriate

* SOME ADJUSTMENTS ARE TO MAKE DATA MORE
EASY TO WORK WITH, OTHERS ARE ADAPTERS MEANT TO FORCE DATA TO CONFORM TO AN
EXISTING CONTRACT, OTHERS ARE MEANT TO WRAP DISTINCT STRATEGIES IN A COMMON
INTERFACE (possibly overlapping too much here), ARE THERE OTHER KINDS?

---examples---

* Draper
* FasterCSV::Row
* Enumerator!
* Arguments and Results

## To think about

* What is the difference between "internals" and "peers"? Are peers any objects
exposed to the larger system, and internals more like Prawn's core objects, Ruby
core objects, etc?

> We should mock an object’s peers—its dependencies, notifications, 
and adjustments... not its internals.

> find the right boundaries for an object so that it plays well with its
neighbors—a caller wants to know what an object does and what it
depends on, but not how it works."


CONTINUE READING THIS!
https://groups.google.com/forum/?fromgroups=#!msg/growing-object-oriented-software/BehKoB1eiFQ/UOcf39B7DYgJ


[GOOS]: http://www.growing-object-oriented-software.com/
[rack]: http://rack.github.com/
[pr-4.11]: https://practicingruby.com/articles/64
[pr-5.2]: https://practicingruby.com/articles/71
[ports-and-adapters]: http://alistair.cockburn.us/Hexagonal+architecture
