The Law of Demeter is a well-known software design principle for reducing
coupling between collaborating objects. However, because the law exists in many
forms, it often means different things to different people. As far as laws go,
Demeter has been flexible in practice, and that has lead to some interesting
evolutions in its applications over time. In this article, we will 
discuss an interpretation of the law that is quite literally out of 
this world.

### An introduction to Smyth's Law of Demeter

[David Smyth](http://zipcodemars.jpl.nasa.gov/bio-contribution.cfm?bid=1018&cid=393&pid=377), 
a scientist who worked on various Mars missions for NASA's Jet 
Propulsion Laboratory, came up with this seemingly innocuous definition
of the Law of Demeter:

> A method can only act upon the message arguments, and the state of the receiving object.

On the surface, this formulation is essentially [the object form of the Law
of Demeter](http://www.ccs.neu.edu/research/demeter/demeter-method/LawOfDemeter/object-formulation.html)
stated in much less formal terms. However, Smyth's law is different in the way
he interprets it: he assumes that the Law of Demeter implies that 
methods should not have return values. This small twist makes 
the law have a much deeper effect than its originators had 
anticipated. 

Before we discuss the implications of building systems entirely out of methods
without return values, it is important to understand why Smyth assumed
that value-returning methods were forbidden in the first place. To explore
that point, consider the following trivial example:

```ruby
class Person < ActiveRecord::Base
  def self.in_postal_area(zipcode)
    where(:zipcode => zipcode)  
  end
end
```

The `Person.in_postal_area` method itself does not violate the 
Law of Demeter, as it is nothing more than a simple delegation
mechanism which passes the `zipcode` parameter on to a 
lower-level function on the same object. But because it
returns a value, this function makes it easy for its callers
to violate the Law of Demeter, as shown below:

```ruby
class UnsolicitedMailer < ActionMailer::Base
  def spam_postal_area(zipcode)
    people = Person.in_postal_area(zipcode)

    emails = people.map { |e| e.email }

    mail(:to => emails, :subject => "Offer for you!")
  end
end
```

In `UnsolicitedMailer#spam_postal_area`, the value returned by
`Person.in_postal_area` is neither part of the internals
of the `UnsolicitedMailer` object, nor an argument that was passed 
into the function. This makes it a Demeter violation to send any
messages to the object that `Person.in_postal_area` returns. 
Depending on the project's requirements, breaking the law in
this fashion could be perfectly acceptable, but it is a code
smell to watch out for.

In the context of the typical Ruby project, methods that 
return values are common, because the convenience of implementing
things this way often outweighs the cost of doing so. However,
whenever you take this approach, you make two fundamental 
assumptions that those who write code for Mars rovers 
simply cannot: that your value-returning methods will respond
in a reasonable amount of time, and that they will not fail 
in all sorts of complicated ways.

While these basic assumptions often apply to the bulk of what we do,
even those of us who aren't rocket scientists occasionally
need to work on projects where temporal coupling is considered
harmful, and robust failure handling is essential. In those
scenarios, it is worth considering what Smyth's interpretation
of the Law of Demeter has to offer.

### The implications of Smyth's Law of Demeter

-----


This means that you can only make direct calls to objects stored in instance
variables, and direct calls to argument objects. I wonder if this implies that
object state should also be injected (although the practical implications of
that are minimal)

Not sure how these rules apply to collections. Presumably it must be acceptable
to do something like: data.each { |e| e.foo } or data[0].bar. QUESTION: Is LoD 
meant for objects only and not datastructures?

Law of Demeter and callbacks. Is a block-based callback any different inu
pros/cons than an method-call based one?

Implications:

    1. Method bodies tend to be very close to straight-line code. Very simple logic,
    very low complexity.

    2. There must be no return values, or else the sender of the message cannot be
    obeying the law.

    3. There cannot be tight synchronization, as the sender cannot tell if
    the message is acted on or not within any "small" period of time. (However,
    it may be possible to detect a timeout if there is a two way protocol between
    the objects)

    4. Since there are no return values, the objects need to be "responsible"
    objects, handling both the expected cases and the predictable failure cases.
    This localizes failure handling within the object that has the best
    visibility/understanding of what could have gone wrong. (see correspondence for
    more)

    5. The law requires an object to subscribe to information, preventing lazy
    evaluation. This isn't a problem as long as object responsibilities are
    concise (think about this)

    6. Because tight synchronization is not allowed, objects should be
    goal-oriented. A goal is different than a method because it is persued over
    some period of time, and does not seem instantanious. Thinking in terms
    of goals rather than discrete actions allows for the discovery of solutions
    which do not require tight temporal coupling.

    "Temporal coupling and synchronization is elminated, therefore avoiding three of
    the nastiest problems in real-time and distributed systems: critical sections,
    priority inversions, and deadlock" <-- ((over my head)).

    "We have found breaking LoD is very expensive! On Mars Pathfinder, integration
    costs of law breaking parts of the system were at least an order of magnitude 
    higher, had to pay it on every integration cycle, not just once."


### Smyth's Law of Demeter in practice

- Show space_explorer examples

- talk about areas where it was easy
  - when to use method-based callbacks
  - when to use block-based callbacks 

- talk about areas where violations were necessary:
  - collections, low level data (i.e. make an exception for core objects, apply
    law to domain objects)

[[[[[[ SEE ALSO, UNCLE BOB, DATA STRUCTURES VS. OBJECTS ]]]]
http://blog.objectmentor.com/articles/2007/11/02/active-record-vs-objects

- show how the code nicely abstracts away temporal coupling
- have readers do error handling as an exercise

### Reflections
