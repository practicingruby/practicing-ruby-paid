Conventional wisdom says that concurrent programming is hard, especially in 
Ruby. This basic assumption is what lead many Rubyists to take an interest
in languages like Erlang and Scala -- their baked in support for 
the [actor model][actors] is meant to make concurrent systems 
much easier for everyday programmers to implement and understand.

But do you really need to look outside of Ruby to find concurrency primitives
that can make your work easier? The answer to that question probably 
depends on the levels of concurrency and availability that you require, but
things have definitely been shaping up in recent years. In particular, 
the [Celluloid][celluloid] framework has brought us a convenient and clean way to implement
actor-based concurrent systems in Ruby.

In order to appreciate what Celluloid can do for you, you first need to
understand what the actor model is, and what benefits it offers over the
traditional approach of directly using threads and locks for concurrent 
programming. In this article, we'll try to shed some light on those points by
solving a classic concurrency puzzle in three ways: Using Ruby's built-in
primitives (threads and mutex locks), using the Celluloid framework, and using a
minimal implementation of the actor model that we'll build from scratch.

By the end of this article, you certainly won't be a concurrency expert
if you aren't already, but you'll have a nice head start on some
basic concepts that will help you decide how to tackle concurrent programming
within your own projects. Let's begin!

## The Dining Philosophers Problem

The [Dining Philosophers][philosophers] problem was formulated by Edgar Djisktra in 1965 to
illustrate the kind of issues we can find when multiple processes compete to
gain access to exclusive resources.

In this problem, five philosophers meet to have dinner. They sit at a round
table and each one has a bowl of rice in front of them. There are also five
chopsticks, one between each philosopher. The philosophers spent their time
thinking about _The Meaning of Life_. Whenever they get
hungry, they try to eat. But a philosopher needs a chopstick in each
hand in order to grab the rice. If any other
philosopher has already taken one of those chopsticks, the hungry
philosopher will wait until chopstick is available.

This problem is interesting because if it is not properly solved it can easly
lead to deadlock issues. We'll take a look at those issues soon, but first let's
convert this problem domain into a few basic Ruby objects.

### Modeling the table and its chopsticks

All three of the solutions we'll discuss in this article rely on a `Chopstick`
class and a `Table` class. The definitions of both classes are shown below:

```ruby
class Chopstick
  def initialize
    @mutex = Mutex.new
  end

  def take
    @mutex.lock
  end

  def drop
    @mutex.unlock

  rescue ThreadError
    puts "Trying to drop a chopstick not acquired"
  end

  def in_use?
    @mutex.locked?
  end
end

class Table
  def initialize(num_seats)
    @chopsticks  = num_seats.times.map { Chopstick.new }
  end

  def left_chopstick_at(position)
    index = (position - 1) % @chopsticks.size
    @chopsticks[index]
  end

  def right_chopstick_at(position)
    index = (position + 1) % @chopsticks.size
    @chopsticks[index]
  end

  def chopsticks_in_use
    @chopsticks.select { |f| f.in_use? }.size
  end
end
```

The `Chopstick` class is just a thin wrapper around a regular Ruby mutex 
that will ensure that two philosophers can not grab the same chopstick 
at the same time. The `Table` class deals with the geometry of the problem; 
it knows where each seat is at the table, which chopstick is to the left 
or to the right of that seat, and how many chopsticks are currently in use.

Now that you've seen the basic domain objects that model this problem, we'll
look at different ways of implementing the behavior of the philosophers. 
We'll start with what *doesn't* work.

## A solution that leads to deadlocks

```ruby
class Philosopher
  def initialize(name)
    @name = name
  end

  def dine(table, position)
    @left_chopstick  = table.left_chopstick_at(position)
    @right_chopstick = table.right_chopstick_at(position)

    loop do
      think
      eat
    end
  end

  def think
    puts "#{@name} is thinking"
  end

  def eat
    take_chopsticks

    puts "#{@name} is eating."

    drop_chopsticks
  end

  def take_chopsticks
    @left_chopstick.take
    @right_chopstick.take
  end

  def drop_chopsticks
    @left_chopstick.drop
    @right_chopstick.drop
  end
end
```

```ruby
names = %w{Heraclitus Aristotle Epictetus Schopenhauer Popper}

philosophers = names.map { |name| Philosopher.new(name) }
table        = Table.new(philosophers.size)

threads = philosophers.map.with_index do |philosopher, i|
  Thread.new { philosopher.dine(table, i) }
end

threads.each(&:join)
sleep
```

### A coordinated mutex-based solution

Introduce a waiter!

```ruby
class Waiter
  def initialize(capacity)
    @capacity = capacity
    @mutex    = Mutex.new
  end

  def serve(table, philosopher)
    @mutex.synchronize do
      sleep(rand) while table.chopsticks_in_use >= @capacity 
      philosopher.take_chopsticks
    end

    philosopher.eat
  end
end
```

```ruby
class Philosopher

  # ... all omitted code same as before

  def dine(table, position, waiter)
    @left_chopstick  = table.left_chopstick_at(position)
    @right_chopstick = table.right_chopstick_at(position)

    loop do
      think

      # instead of calling eat() directly, make a request to the waiter 
      waiter.serve(table, self)
    end
  end

  def eat
    # removed take_chopsticks call, as that's now handled by the waiter

    puts "#{@name} is eating."

    drop_chopsticks
  end
end
```

```ruby
names = %w{Heraclitus Aristotle Epictetus Schopenhauer Popper}

philosophers = names.map { |name| Philosopher.new(name) }

table  = Table.new(philosophers.size)
waiter = Waiter.new(philosophers.size - 1)

threads = philosophers.map.with_index do |philosopher, i|
  Thread.new { philosopher.dine(table, i, waiter) }
end

threads.each(&:join)
sleep
```

## An actor-based solution using Celluloid

```ruby
class Philosopher
  include Celluloid

  def initialize(name)
    @name = name
  end

  def dine(table, position, waiter)
    @waiter = waiter

    @left_chopstick  = table.left_chopstick_at(position)
    @right_chopstick = table.right_chopstick_at(position)

    think
  end

  def think
    puts "#{@name} is thinking."
    sleep(rand)

    @waiter.async.request_to_eat(Actor.current)
  end

  def eat
    take_chopsticks

    puts "#{@name} is eating."
    sleep(rand)

    drop_chopsticks

    @waiter.async.done_eating(Actor.current)

    think
  end

  def take_chopsticks
    @left_chopstick.take
    @right_chopstick.take
  end

  def drop_chopsticks
    @left_chopstick.drop
    @right_chopstick.drop
  end

  def finalize
    drop_chopsticks
  end
end

class Waiter
  include Celluloid

  def initialize(philosophers)
    @eating   = []
    @capacity = philosophers.size - 1
  end

  def request_to_eat(philosopher)
    if @eating.size < @capacity
      @eating << philosopher
      philosopher.async.eat
    else
      Actor.current.async.request_to_eat(philosopher)
    end
  end

  def done_eating(philosopher)
    @eating.delete(philosopher)
  end
end
```

```ruby
names = %w{Heraclitus Aristotle Epictetus Schopenhauer Popper}

philosophers = names.map { |name| Philosopher.new(name) }

waiter = Waiter.new(philosophers.size - 1)
table = Table.new(philosophers.size)

philosophers.each_with_index do |philosopher, i| 
  philosopher.async.dine(table, i, waiter) 
end

sleep
```

## Rolling our own actor model

PUT ACTOR CODEZ HERE!

```ruby
class Philosopher
  include Actor

  def initialize(name)
    @name = name
  end

  def dine(table, position, waiter)
    @waiter = waiter

    @left_chopstick  = table.left_chopstick_at(position)
    @right_chopstick = table.right_chopstick_at(position)

    think
  end

  def think
    puts "#{@name} is thinking."
    sleep(rand)

    @waiter.async.request_to_eat(Actor.current)
  end

  def eat
    take_chopsticks

    puts "#{@name} is eating."
    sleep(rand)

    drop_chopsticks

    @waiter.async.done_eating(Actor.current)

    think
  end

  def take_chopsticks
    @left_chopstick.take
    @right_chopstick.take
  end

  def drop_chopsticks
    @left_chopstick.drop
    @right_chopstick.drop
  end
end

class Waiter
  include Actor

  def initialize(capacity)
    @eating = []
    @capacity = capacity
  end

  def request_to_eat(philosopher)
    if @eating.size < @capacity
      @eating << philosopher
      philosopher.async.eat
    else
      Actor.current.async.request_to_eat(philosopher)
    end
  end

  def done_eating(philosopher)
    @eating.delete(philosopher)
  end
end
```

```ruby
names = %w{Heraclitus Aristotle Epictetus Schopenhauer Popper}

philosophers = names.map { |name| Philosopher.new(name) }

table  = Table.new(philosophers.size)
waiter = Waiter.new(philosophers.size - 1)

philosophers.each_with_index { |philosopher, i| philosopher.async.dine(table, i, waiter) }

sleep
```

## TODO: Incorporate the rest of this prose up top...

The philosophers themselves are also pretty simple. They can only seat a table,
pick and drop chopsticks, think and eat.

Although this code is quite simple it will fail miserably if we run it
concurrently. To illustrate the problem let's run this code creating one thread
per philosopher.

```ruby
names = %w{Heraclitus Aristotle Epictetus Schopenhauer Popper}

philosophers = names.map { |name| Philosopher.new(name) }

table = Table.new(philosophers)

threads = philosophers.map.with_index do |philosopher, i|
  Thread.new do 
    philosopher.seat(table, i) 
    
    loop do
      philosopher.think
      philosopher.eat
    end
  end
end

threads.each(&:join)
sleep
```

After some time this code will crash. The Ruby interpreter itself will detect
the issue and give us a useful hint with this message:


```shell
Aristotle is thinking
Popper is eating.
Popper is thinking
Epictetus is eating.
Epictetus is thinking
Heraclitus is eating.
Heraclitus is thinking
Schopenhauer is eating.
Schopenhauer is thinking

dining_philosophers_uncoordinated.rb:79:in `join': deadlock detected (fatal)
  from dining_philosophers_uncoordinated.rb:79:in `each'
  from dining_philosophers_uncoordinated.rb:79:in `<main>
```

We have reach a situation in which each philosopher is hungry and trying to eat.
Each one of them has already picked the left chopstick and is waiting for
the right chopstick. Since all of them are hungry and waiting to eat, no
one of them will drop the left chopstick and we have reached a deadlock.


## A solution using mutexes

One easy solution to this issue is introduce a waiter in the table. In this
model, the philosopher must ask the waiter before eating. If the number of chopsticks
in use is four or more, the waiter will make wait the philosopher, so at least
one philosopher will be able to eat at any time and the deadlock will be
avoided.

There's still a catch. From the moment the waiter checks the number of chopstick
in use until the next philosopher start to eat we have a critical region. That
is: if we let two concurrent threads to execute that code at the same time there
is still a chance of a deadlock. Let's say the waiter checks the number of
chopsticks used and see it is 3. At that moment, the scheduler yields control to
another philosopher who is just picking the chopstick. When the execution flow
comes back to the original thread, it will allow the original philosopher to
eat, even if there are maybe more than four chopsticks already in use.

To avoid this situation we need to protect the critical region with a mutex.
(FIXME: Give more specific explanations of the changes made)

```ruby
class Chopstick
  # ...
 
  def in_use?
    @mutex.locked?
  end
end

class Philisopher
  # ...

  def eat
    # don't call pick_chopsticks, expect waiter to do that

    puts "#{name} is eating."

    drop_chopsticks
  end
end

## FIXME: Consider adding a proper Waiter class

class Table
  attr_reader :chopsticks, :philosophers

  def initialize(philosophers)
    # ...

    @mutex = Mutex.new
  end

  # ... 

  def request_to_eat(philosopher)
    @mutex.synchronize do
      sleep(rand) while chopsticks_in_use >= max_chopsticks
      philosopher.pick_chopsticks
    end

    philosopher.eat
  end

  def max_chopsticks
    chopsticks.size - 1
  end

  def chopsticks_in_use
    @chopsticks.select { |f| f.in_use? }.size
  end
end
```

We also need to make a small change to the runner code so that rather than
eating on their own, the philisopher makes a request to the waiter:

```ruby
  # FIXME: CLEANUP

  Thread.new do 
    philosopher.seat(table, i) 
    
    loop do
      philosopher.think
      table.request_to_eat(philosopher)
    end
  end
```

This code fine and solves the issue, but using mutexes to synchronize code seems
a little low level thinking. Even though this is a simple problem it still has
some gotchas. In one more complicated it is really difficult to keep track of
all the critical regions and be sure that the code behaves properly when
accessing them.

The actor model tries to be a more systematic and object oriented way to deal
with the shared data between threads.


## A solution using Celluloid

Now let me show you a similar solution using Celluloid. Don't worry if you don't
understand how everything is working. We'll spend the rest of the article trying
to explain the inner workings of this code.

```ruby

class ActorPhilosopher < Philosopher
  include Celluloid

  def seat(table, position)
    @waiter = table.waiter

    @left_chopsitck  = table.left_chopsitck_for(position)
    @right_chopsitck = table.right_chopsitck_for(position)

    think
  end

  def think
    puts "#{name} is thinking."
    sleep(rand)
    @waiter.request_to_eat!(Actor.current)
  end

  def eat
    pick_chopsitcks
    puts "#{name} is eating."
    sleep(rand)
    drop_chopsitcks
    @waiter.done_eating!(Actor.current)
    think
  end
end

class TableWithWaiter < Table
  attr_reader :waiter

  def initialize(philosophers, waiter)
    super(philosophers)
    @waiter = waiter
  end
end

class Waiter
  include Celluloid

  def initialize(philosophers)
    @eating = []
    @max_eating = philosophers.size - 1
  end

  def request_to_eat(philosopher)
    if @eating.size < @max_eating
      @eating << philosopher
      philosopher.eat!
    else
      Actor.current.request_to_eat!(philosopher)
      Thread.pass
    end
  end

  def done_eating(philosopher)
    @eating.delete(philosopher)
  end
end

```

In this solution we have introduced a waiter that keeps the count of the
philosophers that are trying to eat. There are some points worth noticing in
this code.

* We don't manage threads and mutexes explicitly. The Celluloid library takes
care of that in a OO way.

* Each class which include the Celluloid module will act as an actor.

* Celluloid will create thread for each of these actor objects.

* The Celluloid library will intercept any unknown method that ends with a ! and
store the method call in the actor's mailbox. The actor's thread will execute
sequentially those stored methods, one after another.

* If we encapsulate the data properly inside the actor classes, only the actor's
thread will be able to access and modify the actor's data. That prevents that
two threads could modify the data leading to deadlocks or data corruption.

## Rolling out our own minimal Actor Library

To illustrate how Celluloid works I'll try to roll out a minimal actors library.
Of course it will not be a full fledged library like Celluloid, but it will
hopefully capture the same functionality in less than sixty lines of Ruby code.

```ruby
require 'thread'

module Actor
  module ClassMethods
    def new(*args, &block)
      Thread.current[:actor] = Proxy.new(super)
    end
  end

  class << self
    def included(klass)
      klass.extend(ClassMethods)
    end

    def current
      Thread.current[:actor]
    end
  end
end

class Proxy
  def initialize(target)
    @target  = target
    @mailbox = Queue.new
    @running = true

    run
  end

  def run
     Thread.new do
      Thread.current[:actor] = self

      begin
        while @running
          method, args = @mailbox.pop
          @target.send(method, *args)
        end
      rescue Exception => ex
        puts "Error while running actor: #{ex}"
        puts ex.backtrace.join("\n")
      end
    end
  end

  def terminate
    @running = false
  end

  def method_missing(method, *args)
    if match = method.to_s.match(/(.*)!$/)
      unbanged_method = match[1]
      @mailbox << [unbanged_method, args]
    else
      @target.send(method, *args)
    end
  end
end

```

The Actor module will be the equivalent of Celluloid. Any class including this
module will be converted into an actor and will be able to receive asynchronous
calls. The module itself overrides the new method of the target class so we can
return a proxy object every time an an object of the target class is
instantiated. We also store the proxy object in a thread level variable. This is
because when sending messages between actors, if we refer to self in methods
calls we will exposed the inner target object, instead of the proxy. This same
[gotcha is also present in Celluloid](https://github.com/celluloid/celluloid/wiki/Gotchas).

Now if we have a Philosopher class including the Actor module any time we
instantiate a philosopher we will actually receive an instance of Actor::Proxy.

The Proxy class will itself execute the actor behavior. Upon instantiation it
will create a mailbox to store the incoming async messages and a thread to
process those messages. The inbox is just a queue so that the incoming message a
processes sequentially even if they arrive at the same time. The actor's thread
will be blocked, trying to pop an object from the queue, until an async message
comes.

One point worth noticing is that there a no restrictions on the kind of messages
that we pass between actors. In other actor model implementation, like Erlang,
the messages between actor must be immutable. That is, once an actor pass a
message to another actor, the original actor is unable to modify this message.
This restriction ensures that the two actor can't concurrently modify the same
data.

Celluloid, instead, tries to mimic regular Ruby method calls, and don't impose
any restriction on the objects that can be passed around actors. It is up to the
developer itself to ensure that the data passed to an actor is no further
modified elsewhere.

[actors]: http://en.wikipedia.org/wiki/Actor_model
[celluloid]: http://celluloid.io/
[philosophers]: http://en.wikipedia.org/wiki/Dining_philosophers
