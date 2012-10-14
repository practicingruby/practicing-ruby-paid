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
rough categorizations do a good job of helping identify the kind of
connection that exists between two objects, and that makes it easier
to think about the rules that apply to that kind of relationship 
within a particular context. By the time you're done reading, you will
be able to easily identify these stereotypes in any system, 
and that will enable you to have a more nuanced view of the 
relationships that exist within it.

## Dependencies

> Services that the object requires from its peers so it can perform its
> responsibilities. The object cannot function without these services. It should
> not be possible to create the object without them.

* Dependencies are essential services that an object can't do its job without.
(e.g. a Canvas object in a graphics system, a client for a payment gateway, etc.)

* Dependencies are injected via the constructor if they're needed object-wide,
otherwise they are passed as required function parameters. (It is essential to
ensure that dependencies are never in a null state)

* Hidden dependencies lead to brittle code

* Can be internal dependencies (on other business objects), external
dependencies (third-party libraries), or adapters. (IS THIS A USEFUL WAY TO
BREAK THINGS DOWN?)

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
> knows nor cares which peers are listening.

* Notifications are a one-way communication mechanism: listeners cannot call
back to the notifier, return a value, or raise an exception, otherwise they may
interrupt other listeners (there are probably some caveats to this, but this
is a heuristic, not a hard and fast rule)

* Notifier can use a sensible default for notifications (such as an empty
collection)

* The abstraction of a notification cuts both ways: The notifier does not know
how its listeners will handle the messages it broadcasts to them, and the
listeners do not have knowledge of the identity or processes involved in
notification.

* Can be codeblocks, objects stored in an array, things on the other end of a
queue, etc. (TAKE A LOOK THROUGH THE DEMETER ARTICLE, TRY TO COME UP WITH
A COUPLE EXAMPLES OF DIFFERENT KINDS OF NOTIFICATIONS AND DISCUSS THEIR
TRADEOFFS, INCLUDING THE #call INTERFACE)

---examples---

* Most use of logging systems
* Event loops
* Typhoeus
* Mike's example? (Which is really quite good, if you start with usage example)
* Mailhopper

## Adjustments

> Peers that adjust the object’s behavior to the wider needs of the system. This
includes policy objects that make decisions on the object’s behalf...and
component parts of the object if it’s a composite.

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


[GOOS]:  http://www.growing-object-oriented-software.com/
