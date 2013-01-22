The popular knowledge says programming concurrency is hard, and traditonally
concurrency has been one of the weakest features in the Ruby language. If you
wanted to do some serious concurrency, you'd better employ a more suitable
languages, like Erland or Scala. Those languages provide powerful concurrency
features somehow inspired by the Actor Model.

If it's still the case that you should use one of those languages to do
concurrency it a debatable question and probably depends on the levels of
concurrency and availability that you need to achieve. The good news is that now
Ruby has also it own popular gem, Celluloid, for concurrent programming using
the principles of the Actor Model.

But what it is exactly the Actor Model? What kind of problems does it solves?
How it is better than the traditional approach of using threads and locks?

This article tries to answer these questions. First we will look at some of the
typical issues we can find in a concurrent applications such as deadlocks. We
will use the classic problem of the Dining Philosophers, proposed by Edgar
Djisktra to illustrate this issue.

Then we will look how to solve this problem using threads and mutexes and also
using the Celluloid gem to get a grasp of how an actor based solutions differ
from a traditional one.

Finally, we will roll out our own minimal actor library to also solve the
problem and get a deeper understanding of the core principles in the Celluloid
library.

Let's begin!

## The Dining Philosophers Problem

The Dinning Philosophers is a problem proposed by Edgar Djisktra in 1965 to
illustrate the kind of issues we can find when multiple processes compete to
gain access to exclusive resources.

In this problem, five philosophers meet to have dinner. They seat at a round
table and each one have a bowl of rice in front of him. There are also five
chopstick, one between each philosopher. The philosophers spent their time
thinking about _The Meaning of Life_. After some time of thinking they get
hungry and try to eat. But the philosopher needs a chopstick in both
hands in order to grab the rice. If any other
philosopher has already taken one of those chopstick chopstick, the hungry
philosopher will wait until chopstick is available.

This problem is interesting because if it is not properly solved it can easly
lead to deadlock issues. To illustrate those issues lets first model the problem
in Ruby.

```ruby
class Chopstick
  def initialize
    @mutex = Mutex.new
  end

  def pick
    @mutex.lock
  end

  def drop
    @mutex.unlock
  end
end

class Table
  attr_reader :chopsticks, :philosophers

  def initialize(philosophers)
    @philosophers = philosophers
    @chopsticks   = philosophers.size.times.map { Chopstick.new }
  end

  def left_chopstick_at(position)
    index = position % chopsticks.size
    chopsticks[index]
  end

  def right_chopstick_at(position)
    index = (position + 1) % chopsticks.size
    chopsticks[index]
  end
end


class Philosopher
  attr_reader :name, :thought, :left_chopstick, :right_chopstick

  def initialize(name)
    @name = name
  end

  def seat(table, position)
    @left_chopstick  = table.left_chopstick_at(position)
    @right_chopstick = table.right_chopstick_at(position)
  end

  def think
    puts "#{name} is thinking"
  end

  def eat
    pick_chopsticks

    puts "#{name} is eating."

    drop_chopsticks
  end

  def pick_chopsticks
    left_chopstick.pick
    right_chopstick.pick
  end

  def drop_chopsticks
    left_chopstick.drop
    right_chopstick.drop
  end
end
```

The code is fairly self-explanatory. The chopstick class is just a thin wrapper
around a regular Ruby mutex that will ensure that two philosophers can not grab
the same chopstick at the same time. The Table class deals with the geometry of
the problem; it knows where each philosopher is seated and which chopstick is to
the left or to the right of that position.

The philosophers themselves are also pretty simple. They can only seat a table,
pick and drop chopsticks, think and eat.

Although this code is quite simple it will fail miserably if we run it
concurrently. To illustrate the problem let's run this code creating one thread
per philosopher.

```ruby

names = %w{Heraclitus Aristotle Epictetus Schopenhauer Popper}

philosophers = names.collect { |name| Philosopher.new(name) }

table = Table.new(philosophers)

threads = philosophers.each_with_index.collect do |philosopher, i|
  Thread.new { philosopher.seat(table, i) }
end

threads.each(&:join)

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

```ruby

class CoordinatedPhilosopher < Philosopher

  def think
    puts "#{name} is thinking."

    # sleep(rand)

    @table.request_to_eat(self)
  end

  def eat
    puts "#{name} is eating."

    # sleep(rand)

    drop_chopsitcks

    think
  end
end

class TableWithMutex < Table
  def initialize(philosophers)
    super
    @mutex = Waiter.new(philosophers)
  end

  def request_to_eat(philosopher)
    @mutex.synchronize do
      sleep(rand) while chopsitcks_in_use >= max_chopsitcks
      philosopher.pick_chopsitcks
    end

    philosopher.eat
  end

  def max_chopsitcks
    chopsitcks.size - 1
  end

  def chopsitcks_in_use
    @chopsitcks.select { |f| f.in_use? }.size
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
