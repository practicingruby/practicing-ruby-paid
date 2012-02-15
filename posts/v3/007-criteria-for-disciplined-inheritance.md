Inheritance is a key concept in most object oriented languages, but applying it skillfully can be challenging in practice. Back in 1989, [M. Sakkinen](http://users.jyu.fi/~sakkinen/) wrote a paper called [Disciplined inheritance](http://scholar.google.com/scholar?cluster=5893037045851782349&hl=en&as_sdt=0,7&sciodt=0,7) that addresses these problems and offers some useful criteria for working around them. Despite being over two decades old, this paper is extremely relevant to the modern Ruby programmer. 

Sakkinen's central point seems to be that most traditional uses of inheritance lead to poor encapsulation, bloated object contracts, and accidental namespace collisions. He provides two patterns for disciplined inheritance, and suggests that by normalizing the way we model things, we can apply these two patterns to a very wide range of scenarios. He goes on to show that code which conforms to these design rules can easily be modeled as ordinary object composition, exposing a solid alternative to traditional class-based inheritance.

These topics are exactly what this two part article will cover, but before we can address them, we should establish what qualifies as inheritance in Ruby. The general term is somewhat overloaded, so a bit of definition up front will help start us off on the right foot. 

### Flavors of Ruby inheritance

Although classical inheritance is centered around the concept of code sharing via class-based hierarchies, modern object oriented programming languages provide many different mechanisms for code sharing. Ruby is no exception, providing four common ways to model inheritance-based relationships between objects.

* Classes provide a single-inheritance model similar to what is found in many other object oriented languages, albeit lacking a few privacy features.

* Modules provide a mechanism for modeling multiple inheritance which is easier to reason about than C++ style class inheritance but is more powerful than Java's interfaces.

* Transparent delegation techniques make it possible for a child object to dynamically forward messages to a parent object. This has similar effects to class/module based modeling on the child object's contract, but preserves encapsulation between the objects.

* Simple aggregation techniques make it possible to compose objects for the purpose of code sharing. This technique is most useful when the subobject is not meant to be a drop-in replacement for the superobject.

While most problems can be modeled using any one of these techniques, they each have their own strengths and weaknesses. Throughout both parts of this article, I'll point out the trade-offs between them whenever it makes sense to do so.

### Modeling incidental inheritance 

Sakkinen describes **incidental inheritance** as the use of an inheritance-based modeling approach to share implementation details between dissimiliar objects. That is to say that child (consumer) objects do not have an _is-a_ relationship to their parents (dependencies), and so do not need to provide a superset of their parent's functionality.

In theory, incidental inheritance is easy to implement in a disciplined way because it does not impose complex constraints on the relationships between objects within a system. As long as the child object is capable of working without errors for the behaviors it is meant to provide, it does not need to take special care to adhere to the [Liskov Substitution Principle](http://blog.rubybestpractices.com/posts/gregory/055-issue-23-solid-design.html). In fact, the child only needs to expose and interact with the bits of functionality from the parent object which are specifically relevant to its domain.

Regardless of what model of inheritance is used, Sakkinen's paper suggests that child objects should only rely on functionality provided by immediate ancestors. This is essentially an inheritance-oriented parallel to the [Law of Demeter](http://en.wikipedia.org/wiki/Law_of_Demeter), and sounds like good advice to follow whenever it is practical to do so. However, this constraint would be challenging to enforce at the language level in Ruby, and may not be feasible to adhere to in every imaginable scenario. In practice, the lack of adequate privacy controls in Ruby make traditional class-hierarchies or module mixins quite messy for incidental inheritance, and that complicates things a bit. But before we discuss that problem any further, we should establish what incidental inheritance looks like from several different angles in Ruby.

In the following set of examples, I construct a simple `Report` object which computes the sum and average of numbers listed in a text file. I break this problem into three distinct parts: a component which provides functionality similar to Ruby's `Enumerable` module, a component which uses those features to do simple calculations on numerical data, and a component which outputs the final report. The contrived nature of this scenario should make it easier to examine the structural differences between Ruby's various ways of implementing inheritance relationships, but be sure to keep some more realistic scenarios in the back of your mind as you work through these examples. 

The classical approach of using a class-hierarchy for code sharing is worth looking at, even if most practicing Rubyists would quickly identify this as the wrong approach to this particular problem. It serves as a good baseline for identifying the problems introduced by inheritance and how to overcome them. As you read through the following code, think of its strengths and weaknesses, as well as any alternative ways to model this scenario that you can come up with.

```ruby
class EnumerableCollection
  def size
    count = 0
    each { |e| count += 1 }
    count
  end

  # Samnang's implementation from Issue 2.4
  def reduce(arg=nil) 
    return reduce {|s, e| s.send(arg, e)} if arg.is_a?(Symbol)

    result = arg
    each { |e| result = result ? yield(result, e) : e }

    result
  end
end

class StatisticalCollection < EnumerableCollection
  def sum
    reduce(:+) 
  end

  def average
    sum / size.to_f
  end 
end

class StatisticalReport < StatisticalCollection
  def initialize(filename)
    self.input = filename
  end

  def to_s
    "The sum is #{sum}, and the average is #{average}"
  end

  private 

  attr_accessor :input

  def each
    File.foreach(input) { |e| yield(e.chomp.to_i) }
  end
end

puts StatisticalReport.new("numbers.txt")
```

* Using modules

```ruby
module SimplifiedEnumerable
  def size
    count = 0
    each { |e| count += 1 }
    count
  end

  # Samnang's implementation from Issue 2.4
  def reduce(arg=nil) 
    return reduce {|s, e| s.send(arg, e)} if arg.is_a?(Symbol)

    result = arg
    each { |e| result = result ? yield(result, e) : e }

    result
  end
end

module Statistics
  def sum
    reduce(:+) 
  end

  def average
    sum / size.to_f
  end 
end

class StatisticalReport
  include SimplifiedEnumerable
  include Statistics

  def initialize(filename)
    self.input = filename
  end

  def to_s
    "The sum is #{sum}, and the average is #{average}"
  end

  private 

  attr_accessor :input

  def each
    File.foreach(input) { |e| yield(e.chomp.to_i) }
  end
end

puts StatisticalReport.new("numbers.txt")
```

* Using aggregation

```ruby
require "forwardable"

class EnumerableCollection
  extend Forwardable

  # Forwardable bypasses privacy, which is what we want here.
  delegate :each => :data

  def initialize(data)
    self.data = data
  end

  def size
    count = 0
    each { |e| count += 1 }
    count
  end

  # Samnang's implementation from Issue 2.4
  def reduce(arg=nil) 
    return reduce {|s, e| s.send(arg, e)} if arg.is_a?(Symbol)

    result = arg
    each { |e| result = result ? yield(result, e) : e }

    result
  end

  private

  attr_accessor :data
end

class StatisticalCollection
  def initialize(data)
    self.data = data
  end

  def sum
    data.reduce(:+) 
  end

  def average
    sum / data.size.to_f
  end 

  private

  attr_accessor :data
end

class StatisticalReport
  def initialize(filename)
    self.input = filename
    self.stats = StatisticalCollection.new(EnumerableCollection.new(self))
  end

  def to_s
    "The sum is #{stats.sum}, and the average is #{stats.average}"
  end

  private 

  attr_accessor :input, :stats

  def each
    File.foreach(input) { |e| yield(e.chomp.to_i) }
  end
end

puts StatisticalReport.new("numbers.txt")
```

While it may be a bit hard to see the benefits that aggregation offers in such a trivial scenario, they become more and more clear as systems become more complex. Most scenarios which involve incidental inheritance are actually relatively horizontal problems in nature, but the use of class based inheritance or module mixins forces a vertical call chain which can become very unwieldy to say the least. When taken to the extremes, you end up with object like `ActiveRecord::Base` which have a call chain that is 43 levels deep, or `Prawn::Document` which has a 26 level deep call chain. 

In a language like Ruby that lacks both multiple inheritance and true class-specific privacy for variables and methods, using class-based hierarchies or module mixins for complex forms of incidental inheritance requires a tremendous amount of discipline. For that reason, the extra effort involved in refactoring towards an aggregation based design seems to pale in comparison to the maintenance headaches caused by following the traditional route. For example, in both `Prawn` and `ActiveRecord`, aggregation would make it possible to flatten that chain by an order of magnitude while simultaneously reducing the chance of namespace collisions, dependencies on lookup order, and accidental side effects due to state mutations. It seems like the cost of somewhat more verbose code would be well worth it in these scenarios.

## Reflections

In Issue 3.8, we will move on to discuss an essential form of inheritance that Sakkinen refers to as **completely consistent inheritance**. Exploring that topic will get us closer to the concept of mathematical subtypes, which are much more interesting at the theoretical level than incidental inheritance relationships are. But because Ruby's language features make even the simple relationships described in this issue somewhat challenging to manage in an elegant way, I am still looking forward to hearing your ideas and questions about the things I've covered so far.

A major concern I have about incidental inheritance is that I still don't have a clear sense of where to draw the line between the two extremes I've outlined in this article. This is definitely an area I want to look into more, so please leave a comment if you don't mind sharing your thoughts on this.
