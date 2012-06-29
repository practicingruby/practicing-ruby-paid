*TODO: ADD GREG'S BIO HERE*

Given that Ruby is an object oriented programming language, all Ruby
programs are going to be composed of many objects. However, techniques 
for breaking the functionality of programs into objects can
vary from programmer to programmer. In this article I'm going to walk
through two common approaches to driving that design at a high level:
**data-centric design** and **responsibility-centric design**. I will
briefly sketch the key ideas of each of the design methodologies,
illustrating how one might structure a simple e-commerce application
using each of the methods. I'll then follow up with some advice about
where I've found the different approaches to be particularly helpful
or unhelpful.

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

In a responsibility-centric design, systems are divided up the system by
the behaviors that they must implement. The goal of this division is
to formulate the description of the behavior of the system in terms of
multiple interacting processes, with each process playing a 
separate **role**. For example, in an e-commerce application with a 
responsibility-centric design, you would be likely to find objects 
such as a purchase processor, an inventory tracker, and a user 
authenticator.

The relationships between objects become very similar to the
client/server model. A **client** object will make requests of the server
to perform some service, and a **server** object will provide a public API
for the set of services that it can perform. This relationship is
described by a **contract** - that is a list of requests that can be made
of the server by the client. Both objects must fulfill this contract,
in that the client can only make the requests specified by the API, and
the server must respond by fulfilling those requests when told.

The goal of describing relationships between objects in this way is that
it forces the API for the server object to describe what it does for
the client rather than how it accomplishes it. This means that by its
very nature the implementation of the server must be encapsulated, and
locked away from the client. This means that the client object is only
coupled to the public API of its server objects, which allows developer
to freely change server internals as long as the client still has an 
object to talk to that fulfills the contract.

This analogy of client and server is not to say however that there
are some objects within the system that are clients, and some objects
that are servers. Any object can act as either a client or a server at
any given time. The notions of client and server are only applicable
to the description of the contract. For example, going back to our
e-commerce application, the object playing the role of a purchase
processor may act as a client, and consume the API of an object playing
the role of a credit card processor, while at the same time playing the
role of a server, and having its API consumed by an object playing the
role of a checkout processor.

As you've probably already noticed, because these objects represent the
behavior of the system rather than the data, the objects are not
generally named after "real world" entities. The roles that an object
plays often represent real world processes, and the implementation of
these roles are often named after how they implement the desired role.
So for example, within our system there might be two objects which
can play the role of a delivery scheduler. One might schedule
deliveries by FedEx, and one might schedule deliveries by UPS. So
although they would both implement the API of the delivery scheduler,
one might be called `FedExDeliveryScheduler`, and the other
`UPSDeliveryScheduler`. The client consuming the object wouldn't
know which delivery scheduler it was talking to, only the API of its
server's role.

Another primary idea of these kinds of systems is that data flows
through the system rather than being centrally managed within the 
system. As a result, data typically takes the form of immutable 
value objects. For example, in order to be able to actually schedule a delivery, 
the delivery scheduler is going to need to be given a bill of lading 
containing the items to be shipped and the destination location. 
When it has completed the scheduling of the delivery it might then 
emit an event containing a scheduled delivery receipt. The data 
for the system is contained within the bill of lading, and the 
scheduled delivery receipt, which is really encapsulated in the 
messages that flow between objects rather than inside the objects 
themselves.

This is not to say however that this data is never persisted. When it is
necessary to persist this data, an object playing the role of a
persister must be created, and it must receive messages containing these
values just like any other part of the system. In this way, the
persistance logic generally lives on the boundaries of the system rather
than in the center.

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
And for applications that center primarily around data, the ActiveRecord
pattern works extremely well. However as some large legacy Rails
codebases show, modeling your application domain which is largely about
behavior in a data centric way intrinsically leads to problems over time.

When you have a domain layer whose complexity lies not in it's many data
formats, but in the rules that need to be applied for every user action,
it might be worth exploring a responsibility-centric design.

At the same time, if the domain that one is working in finds it's
complexity primarily in the many different data types that one has to
work with attempting to use a responsibility-centric design is going to
cause severe problems. Every time you need to change the structure of
the data, you will have to tweak things in many places throughout the
code.

### Further references

1) Object-oriented design: a responsibility-driven approach, R. Wirfs-Brock, B. Wilkerson, OOPSLA '89 Conference proceedings on Object-oriented programming systems, languages and applications

2) The object-oriented brewery: a comparison of two object-oriented development methods, Robert C. Sharble, Samuel S. Cohen, ACM SIGSOFT Software Engineering Notes, Volume 18 Issue 2, April 1993

3) Mock Roles, Not Objects, Steve Freeman, Tim Mackinnon, Nat Pryce, Joe Walnes, OOPSLA '04 Companion to the 19th annual ACM SIGPLAN conference on Object-oriented programming systems, languages, and applications

4) A Laboratory For Teaching Object-Oriented Thinking, Kent Beck, Ward Cunningham, OOPSLA '89 Conference proceedings on Object-oriented programming systems, languages and applications
