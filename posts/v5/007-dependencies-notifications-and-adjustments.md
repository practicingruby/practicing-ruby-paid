One of the challenges in object-oriented programming is determining the right
relationships between collaborating objects in a system. Even objects which have
been well thought out individually can be tricky to integrate if specific
attention was not given to how they would relate to other objects.

Peer object stereotypes are useful for thinking through design and clarifying
the purpose of object relationships; they're not meant to be rigidly imposed but
instead provide a useful categorization to make design discussions easier.

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

## Adjustments

> Peers that adjust the object’s behavior to the wider needs of the system. This
includes policy objects that make decisions on the object’s behalf...and
component parts of the object if it’s a composite.

* The job of an adjustment is to shoehorn some data / functionality into the
form required by some other object.

* Adjustments can be initialized to use sensible defaults where appropriate

* CONSIDER SOMETHING LIKE FasterCSV::Row. SOME ADJUSTMENTS ARE TO MAKE DATA MORE
EASY TO WORK WITH, OTHERS ARE ADAPTERS MEANT TO FORCE DATA TO CONFORM TO AN
EXISTING CONTRACT, OTHERS ARE MEANT TO WRAP DISTINCT STRATEGIES IN A COMMON
INTERFACE (possibly overlapping too much here), ARE THERE OTHER KINDS?

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
