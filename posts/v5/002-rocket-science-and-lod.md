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

Smyth's unique interpretation of how to apply LoD eventually 
caught the eye of Karl Lieberherr, an active member of the
Demeter project who had published some of the earliest papers
on the topic. Lieberherr took an interest in Smyth's approach 
because it was clearly different than what the Demeter 
researchers had intended, but potentially useful nonetheless. 
A correspondence between the two led Smyth to share his 
thoughts about what his definition of LoD brings to 
the table. His six key points from the [original discussion](http://www.ccs.neu.edu/research/demeter/demeter-method/LawOfDemeter/Smyth/LoD-revisited2) 
are listed in an abridged form below:

```
There are actually several wonderful properties that fall out 
from this definition of LoD:

     A method can only act upon the message arguments, and the
     existing state of the receiving object.

1. Method bodies tend to be very close to straight-line code. Very
   simple logic, very low complexity.

2. There must be no return values, or else the sender of the message
   cannot be obeying the law.

3. There cannot be tight synchronization, as the sender cannot tell if
   the message is acted on or not within any "small" period of time
   (perhaps the objects collaborate with a two way protocol, and the
   sender can eventually detect a timeout).

4. Since there are no return values, the objects need to be
   "responsible" objects: they need to handle both nominal, and
   forseeable off-nominal cases. This has the wonderful affect of
   localizing failure handling within the object which has the
   best visibilitiy, and understanding, of whatever went wrong.
   It also dramatically reduces the complexity of protocols, and
   clients.

   ...

5. The law requires an object to subscribe to information, so it has
   what it needs whenever it gets a message. This means that lazy
   evaluation can't be used. While this may seem like an inefficiency,
   it only becomes one in practice if the objects don't have concise
   responsibilities. In such a case, efficiency of communication
   bandwidth isn't the real problem.

   ...

6. Since tight syncronization is out of the picture, the responsible
   objects should be goal oriented. A goal is different from a method
   in that a goal is pursued over some expanse of time, and does not
   seem instantaneous. By thinking of goals rather than discrete
   actions, people can derive solutions which don't require tight
   temporal coupling. This sounds like hand waving, and it is -- but
   7 years of doing it shows it really does work.
```

These are deep claims, but the remainder of the discussion between Smyth
and Lieberherr did not elaborate much further on them. However, it is 
fascinating to imagine the kind of programming style that Smyth
is advocating here: it boils down to a highly robust form of
[responsibility-driven development](http://practicingruby.com/articles/64) with 
concurrent (and potentially distributed) objects that communicate almost 
exclusively via callback mechanisms. If Smyth were not an established
scientist working on some of the world's most challenging problems,
it would almost seem as if he was playing object-oriented buzzword bingo.

While I don't know nearly enough about any of these ideas to speak 
authoratively on them, I think that they form a great starting point 
for a very interesting conversation. However, if you're like me, you
probably would benefit from bringing these ideas back down to earth
a bit. With that in mind, I've put together a little example 
program that will hopefully help you do exactly that.

### Smyth's Law of Demeter in practice

Software design principles can be interesting to study in the abstract, but
there is no substitute for trying them out in concrete applications. If you 
can find a project that is a natural fit for the technique you are 
trying to investigate, even the most simple toy application will teach you
more than pure thought experiments ever could.

Smyth's approach to the Law of Demeter originated from his work on software for
Mars rovers, an environment where tight temporal coupling and a lack of 
robust interactions between distributed systems can cause serious problems.
Because it takes about 14 minutes for light to travel between Earth and Mars, 
even the most trivial system interactions require careful design consideration. 
With so much room for things to go wrong, a programming style that claims to 
make it easier to manage these kinds of problems definitely sounds promising.

Of course, you don't need to land robots on Mars to encounter these kind of
challenges. Off the top of my head, I can easily imagine things like payment
processing systems and remote system administration toolchains having a good
degree of overlap with the issues that Smyth's LoD is meant to
address. Still, those problems are not nearly as exciting as driving a little
remote control car around on a different planet. Knowing that, I decided
to test Smyth's ideas by building a very basic Mars rover simulation. The 
short video below shows me interacting with it:

<div align="center">
<iframe width="800" height="600"
src="http://www.youtube.com/embed/Yqofx6MbYFU?vq=480&rel=0" frameborder="0" allowfullscreen></iframe>
</div>

In the video, the communications delay is set at only a couple seconds, but it
can be set arbitrarily high, which makes it possible to simulate the full 14+
minute delay between Earth and Mars. No matter what the delay is set at, the
rover queues up commands as they come in, and sends its responses one 
at a time as its tasks are completed. The entire simulator is only a couple
pages of code, and consists of the following objects and responsibilities:

* [SpaceExplorer::Radio]() relays messages on a time delay.
* [SpaceExplorer::MissionControl]() communicates with the rover.
* [SpaceExplorer::Rover]() communicates with mission control and updates the map.
* [SpaceExplorer::World]() implements the simulated world map.

As I implemented this system, I took care to abide by Smyth's recommendation
that methods should not return meaningful values. While I wasn't so pedantic as
to explicitly return `nil` from each function, I treated them as void functions
internally, and so none of the simulator's features depend on the return value 
of the methods I implemented. This had a major impact on the way I designed 
things overall, and you'll be able to see that as we look at each object
individually.

```ruby
module SpaceExplorer
  class Radio
    def initialize(delay)
      @delay = delay
    end

    def establish_connection(target)
      @target = target
    end

    def transmit(command)
      raise "Target not defined" unless defined?(@target)

      start_time = Time.now

      Thread.new do
        sleep 1 while Time.now - start_time < @delay

        @target.receive_command(command) 
      end
    end
  end
end
```



```ruby
module SpaceExplorer
  class MissionControl
    def initialize(narrator, radio_link)
      @narrator   = narrator
      @radio_link = radio_link
    end

    def send_command(command)
      @radio_link.transmit(command)
    end

    def receive_command(command)
      @narrator.msg(command)
    end
  end
end
```

```ruby
require "thread"

module SpaceExplorer
  class Rover
    def initialize(world, radio_link)
      @world      = world
      @radio_link = radio_link

      @queue = Queue.new

      Thread.new { loop { process_command(@queue.pop) } }
    end

    def receive_command(command)
      @queue.push(command)
    end

    def process_command(command)
      case command
      when "!PING"
        @radio_link.transmit("PONG")
      when "!NORTH", "!SOUTH", "!EAST", "!WEST"      
        @world.move(command[1..-1])
      when "!SNAPSHOT"
        @world.snapshot { |data| transmit_encoded_snapshot(data) }
      else
        # do nothing
      end
    end

    private

    def transmit_encoded_snapshot(data)
      output = data.map { |row| row.join(" ") }.join("\n")

      @radio_link.transmit("\n#{output}")
    end
  end
end
```

```ruby
module SpaceExplorer
  class World
    DELTAS = (-2..2).to_a.product((-2..2).to_a)

    def initialize(data, row, col)
      @data   = data

      @row    = row
      @col    = col
    end

    def move(direction)
      case direction
      when "NORTH"
        @row -= 1
      when "SOUTH"
        @row += 1
      when "EAST"
        @col += 1
      when "WEST"
        @col -= 1
      else
        raise ArgumentError, "Invalid direction!"
      end
    end

    def snapshot
      snapshot = DELTAS.map do |rowD, colD|
        if colD == 0 && rowD == 0
          "@"
        else
          @data[@row + rowD][@col + colD]
        end
      end

      yield snapshot.each_slice(5).to_a
    end
  end
end
```

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

### GROUP PROJECT: Exploring our options for failure handling

### Reflections

---

This means that you can only make direct calls to objects stored in instance
variables, and direct calls to argument objects. I wonder if this implies that
object state should also be injected (although the practical implications of
that are minimal)

Not sure how these rules apply to collections. Presumably it must be acceptable
to do something like: data.each { |e| e.foo } or data[0].bar. QUESTION: Is LoD 
meant for objects only and not datastructures?

Law of Demeter and callbacks. Is a block-based callback any different inu
pros/cons than an method-call based one?

