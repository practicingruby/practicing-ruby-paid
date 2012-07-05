Greg Moeck is a software craftsman who has been working with Ruby for
over 7 years. He is currently employed by Facebook where he does
primarily mobile JavaScript work.

Given that Ruby is an object oriented programming language, all Ruby
programs are going to be composed of many objects. However, techniques 
for breaking the functionality of programs into objects can
vary from programmer to programmer. In this article I'm going to walk
through two common approaches to driving that design at a high level:
**data-centric design** and **responsibility-centric design**. I will
briefly sketch the key ideas of each of the design methodologies,
illustrating how one might structure parts of a simple e-commerce
application using each of the methods. I'll then follow up with some 
advice about where I've found the different approaches to be particularly
helpful or unhelpful.

> **NOTE:** The terms data-centric design and
responsibility-centric design are purposefully similar to
data-driven design and responsibility-driven design. Many of the ideas
presented here have much in common with these two groupings. However I
have diverged somewhat from these common patterns in order to provide a
more Rubyist feel to the designs, and make them more closely related to
what a Rubyist sees in their code every day.

### Data-centric design

In a data-centric design, the system is generally separated into objects
based upon the data that they encapsulate. For example, in an
e-commerce application you are likely to find objects that represent
products, invoices, payments, and users. These objects provide 
methods which operate on that data, either returning its values, 
or mutating its state. An `Product` object might provide a method to 
find how many of those items are currently in stock, or possibly
a method to add that item to the current shopping cart.

Since the data is generally representing something that exists in the
*real world*, objects are almost always nouns that correspond to
something that actually exists in the real world. This real-worldliness 
is generally also true of the methods that the objects provide. 
The methods either represent accessors to the object's data, 
relationships between objects, or actions that could be taken on 
the object. The following ActiveRecord object serves as a good example
of what this style of design looks like:

```ruby
class Product < ActiveRecord::Base
  #relationships between objects
  has_many :categories

  #accessing objects data
  def on_sale?
    not(sale_price.nil?)
  end

  #action to take on the product
  def add_to_cart(cart)
    self.remaining_items -= 1
    save!
    cart.items << self
  end
end
```

Following along these lines, inheritance is generally used as a principle
of classification, establishing a subtype relationship
between the parent and the child. If B inherits from A, that is a
statement that B is a type of A. This is generally described as an "is a"
relationship. For example the classes `LaborCharge` and `ProductCharge`
might both inherit from a base class `LineItem`, because a `LaborCharge` is
a type of `LineItem`, as is `ProductCharge`. The key thing to note
about these classes is that they share at least some data attributes and the
behavior around those attributes, even if some of that behavior might end up
being overridden.

However, not everything can have a counterpart in the real world. There
still needs to be some communication model that is created to describe
the global or system level view of the interactions between objects.
These **controllers** will fetch data from different parts of the system, 
and pipe it into actions in another part.
Since these objects generally are very difficult to classify in a
hierarchical way, it is a good idea to keep them as thin as
possible, pushing as much logic into the actual domain model as you
possibly can.

For those familiar with standard Rails architectures, you should see a
lot of commonalities with the above description. Rails model objects are
inherently structured this way because the ActiveRecord pattern tightly
couples your domain objects to the way in which their data is persisted.
And so all ActiveRecord objects are about some "encapsulated" data, and
operations that can be done on that data. Rails controllers provide the
global knowledge of control, interacting with those models to then
accomplish some tasks.

### Responsibility-centric design

In a responsibility-centric design, systems are divided by the
collection of behaviors that they must implement. The goal of this division is
to formulate the description of the behavior of the system in terms of
multiple interacting processes, with each process playing a
separate **role**. For example, in an e-commerce application with a
responsibility-centric design, you would be likely to find objects
such as a payment processor, an inventory tracker, and a user
authenticator.

The relationships between objects become very similar to the
client/server model. A **client** object will make requests of the server
to perform some service, and a **server** object will provide a public API
for the set of services that it can perform. This relationship is
described by a **contract** - that is a list of requests that can be made
of the server by the client. Both objects must fulfill this contract,
in that the client can only make the requests specified by the API, and
the server must respond by fulfilling those requests when told.

So for example, in our e-commerce application you might find an order
processor that looks something like the following:

```ruby
class StandardOrderProcessor
  def initialize(payment_processor, shipment_scheduler)
    @payment_processor = payment_processor
    @shipment_scheduler = shipment_scheduler
  end

  def process_order(order)
    @payment_processor.debit_accout(order.payment_method, order.amount)
    @shipment_scheduler.schedule_delivery(order.delivery_address,
                                          order.items)
  end
end
```

The goal of describing relationships between objects in this way is that
it forces the API for the server object to describe **what** it does for
the client rather than *how* it accomplishes it. This means that by its
very nature the implementation of the server must be encapsulated, and
locked away from the client. This means that the client object is only
coupled to the public API of its server objects, which allows developer
to freely change server internals as long as the client still has an
object to talk to that fulfills the contract.

So for example the above standard order processor implements the order
processor interface, but so does the following order validation processor:

```ruby
class OrderValidationProcessor
  def initialize(order_processor, error_handler)
    @order_processor = order_processor
    @error_handler = error_handler
  end

  def process_order(order)
    if is_valid_order(order)
      @order_processor.process_order(order)
    else
      @error_handler.invalid_order(order)
    end
  end

  private
  def is_valid_order(order)
    #does some checking for if the order is valid
  end
end
```

The client of the order processor does not need to know which sort of
order processor it is talking to, it just needs to tell it to process
the order. In the case where it was given a standard order processor it
wouldn't go through validation, but in the case where it was given an
order processor validator it would. But the key is that the client
wouldn't know how that processing was going to take place, decoupling
the actual processing of the order.

These objects would generally be composed with a factory that might look
something like this:

```ruby
class OrderProcessorFactory
  ...

  def order_processor_with_validation
    OrderValidationProcessor.new(order_processor_without_validation,
                                error_handler)
  end

  def order_processor_without_validation
    StandardOrderProcessor.new(payment_processor, shipment_scheduler)
  end

  ...
end
```

This analogy of client and server is not to say however that there
are some objects within the system that are clients, and some objects
that are servers. Any object can act as either a client or a server at
any given time. The notions of client and server are only applicable
to the description of the contract. For example, going back to our
e-commerce application, the object playing the role of a payment
processor may act as a client, and consume the API of an object playing
the role of a credit card processor, while at the same time, as above,
playing the role of a server, and having its API consumed by a
standard order processor. In the case of the credit card processor, it
would be the client, whereas in the case of the standard order processor
it would be the server.

The key thing to notice in this client server relationship though is
that the client should only be coupled to the server's API, which
defines the role that the server is playing. The actual server that it's
talking to doesn't matter, just that it implements the contact.

As you've probably already noticed, because these objects represent the
behavior of the system rather than the data, the objects are not
generally named after "real world" entities. The roles that an object
plays often represent real world processes, and the implementation of
these roles are often named after *how* they implement the desired role.
So for example, within our system there might be two objects which
can play the role of a shipment scheduler. One might schedule
deliveries by FedEx, and one might schedule deliveries by UPS. So
although they would both implement the API of the delivery scheduler,
one might be called `FedExDeliveryScheduler`, and the other
`UPSDeliveryScheduler`. The client consuming the object wouldn't
know which delivery scheduler it was talking to, only the API of its
server's role, with the actual object dependency being passed into its
constructor.

Another primary idea of these kinds of systems is that data flows
through the system rather than being centrally managed within the 
system. As a result, data typically takes the form of immutable 
value objects. For example, in the above order processors, the processes
were being passed an order object, which contained the data for a given
order. The objects within the system are not mutating or persisting this
data directly, but passing values around the sytem. And so an object
responsible for tracking the current order might look like this:

```ruby
class CurrentOrderTracker
  def initialize
    @order = Order.new
  end

  def item_selected(item)
    @order = order.add_item(item)
  end

  class Order
    attr_accessor :items

    def initialize(items)
      @items = items || []
    end

    def add_item(item)
      Order.new(@items + item)
    end
  end
end
```
Since any reference to one of these values is guaranteed to be
immutable, any process can read from it at any time without worrying
that it might have been modified by another process.

This is not to say however that this data is never persisted. When it is
necessary to persist this data, an object playing the role of a
persister must be created, and it must receive messages containing these
values just like any other part of the system. In this way, the
persistance logic generally lives on the boundaries of the system rather
than in the center. Such an object might look something like this:

```ruby
class SQLOrderPersister
  #assuming that AROrder is an active record object
  def persist_order(order)
    order = AROrder.find(order.id)
    if order
      order.update_attributes(order.attributes)
    else
      AR.Order.new(order.attributes).save
    end
  end
end
```

The last thing to note is that in this sort of system using inheritance
as a form of classification doesn't really make much sense. Historically
inheritance takes the form of "plays the same role", instead of "is a".
That is, objects which play the same role have historically inherited
from a common abstract base class which merely implements the role's
public API, and forces any class that inherits from it to do the same.
It's really saying that it implements a contract, rather than making a
categorical claim to what the object is.

However inside of a dynamic language like Ruby inheritance for this sort of
relationship this isn't strictly necessary. Due to duck typing, if
something quacks like a duck (that is if it implements the same API as a
duck), it is a duck, and there is no need to have the objects inherit
from a common base class. That being said, it can still be nice to
explicitly name these roles, and an abstract base class can often be
used to do that.

### Comparing and contrasting the two design styles

As with almost any engineering choice, it isn't possible to say that either 
of these two approaches is always superior or inferior. That said, 
we can still walk through some strengths and weaknesses of each approach.

**Strengths of data-centric design:**

1) Because the code is broken into parts around real world entities,
  these entities are easy to find and tweak. All the code relative to a
  certain set of data lives together.

2) Because it has a global flow control, and the fact that it is
  it is centered around data (which people generally understand),
  it is relatively easy for programmers experienced with traditional
  procedural languages to adapt their previous experience into this
  style.

3) It is very easy to model things like create/read/update/destroy
  because the data is found in a single model for all real world
  objects.

4) For systems with many data types and a small amount of behavior, this
  approach evenly distributes the location of the code

**Weaknesses of data-centric design:**

1) Because the structure of an object is a part of the definition of that
  object, encapsulation is generally harder to achieve.

2) Because the system is split according to data, behavior is often hard
  to track down. Similar operations often span across multiple data
  types, and as such end spread out across the entirety of the system

3) The cohesion of behavior within an object is often low since every
  object has to have all actions that could be taken upon it, and those
  actions often have very little to do with one another.

4) In practice it often leads to coupling to the structure of the object
  as one needs to violate the Law of Demeter to traverse the
  relationships of the objects. For example, think of often you in Rails
  you see something like the following:

```ruby
@post.comments.each do |comment|
  if comment.author.something
    ...
  end
end
```

**Strengths of responsibility-centric design:**

1) Objects tend to be highly cohesive around their behavior because that
  is the way that they're being broken into pieces.

2) Objects tend to be coupled to an interface rather than an
  implementation, allowing the changing of behavior through composition.

3) As the behavior of a system increases the number of objects increases
  rather than the lines of code within model objects.


**Weaknesses of responsibility-centric design:**

1) It is often difficult to drop into the code and make simple changes as
  even the simplest change necessitates understanding the architecture
  of at least the module. This means that the on-ramping time for the
  team is generally fairly high.

2) Since there is generally no global control, it is often difficult for
  someone to grasp where things are happening. As Kent Beck, and Ward
  Cunningham have said, "The most difficult problem in teaching object-
  oriented programming is getting the learner to give up the global
  knowledge of control that is possible  with  procedural  programs,
  and rely on the local knowledge of objects to accomplish their
  tasks."

3) Data is not as readily available since the destructuring of the
  application is around behavioral lines. The data can often be
  scattered throughout the system. Which means changing the data
  structure is more expensive than changing the behavior.

### Choosing the right design

Rails has proved how the data centric approach can lead to quickly
building an application that can create, read, update and destroy data.
And for applications whose domain complexity lies primarily in data types,
and the actions that can be taken on those data types, the pattern works
extremely well. Adding or updating data types is fast and easy since the
system is cohesive around its data.

However as some large legacy Rails codebases show, when the complexity
of the domain lies primarily in the behvaiors or rules of the domain
then organizing around data leads to a lot of jumbled code. The models
end up needing to have many methods on them in order to process all of
the potential actions that can be taken on them, and many of these
actions end up being similar accross data types. As such the cohesion of
the system suffers, and extending or modifying the behavior becomes more and
more difficult over time.

The oppisite of course is true as well in my experience. In a system
whose domain complexity lies primarily in its behavior, decomposing the
system around those behaviors makes extending or modifying the behavior
of the system over time to be much faster and easier. However the cost
is that extending or modifying the data of the system can become more
and more difficult over time.

As with most design methods, it comes down to an engineering decision,
which often means you have to guess, and evolve over time. There is no
magic system that will be the right way to model things regardless of
the application. There might even be some subsets of an application
that might be better modeled in a data-centric way, whereas other
sections of the system might be better modeled in a behavior-centric way.
The key thing I've found is to be sensitve to the "thrash" smell, where
you notice that things are becoming more and more difficult to extend or
modify, and be open to refactor the design based on the feedback your
getting from the system.

### Further references

1) Growing Object Oriented Software Guided By Tests, Steve Freeman, Nat Pryce

2) Object-oriented design: a responsibility-driven approach, R. Wirfs-Brock, B. Wilkerson, OOPSLA '89 Conference proceedings on Object-oriented programming systems, languages and applications

3) The object-oriented brewery: a comparison of two object-oriented development methods, Robert C. Sharble, Samuel S. Cohen, ACM SIGSOFT Software Engineering Notes, Volume 18 Issue 2, April 1993

4) Mock Roles, Not Objects, Steve Freeman, Tim Mackinnon, Nat Pryce, Joe Walnes, OOPSLA '04 Companion to the 19th annual ACM SIGPLAN conference on Object-oriented programming systems, languages, and applications

5) A Laboratory For Teaching Object-Oriented Thinking, Kent Beck, Ward Cunningham, OOPSLA '89 Conference proceedings on Object-oriented programming systems, languages and applications
