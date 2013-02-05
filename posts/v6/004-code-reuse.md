Practicing Ruby articles tend to be linear stories, CS papers are often the
cross product of various concepts... this is meant to be along those lines

# The complexities of code reuse

Ruby provides many tools that support convenient code re-use, but each of them
comes with its own caveats and gotchas. This cheatsheet attempts to demonstrate
all the different sources of complexity to be aware of when building reusable
components in Ruby.

## 1. Ways to reuse code

### 1.1 Class inheritance

Subclassing allows you to use the features of a base class within your own
class definition. Because Ruby is a single-inhertance language, each class has
exactly one porent, so you need to choose wisely.

A typical example of class inheritance in Ruby is found in ActiveRecord:

```ruby
class Product < ActiveRecord::Base
  belongs_to :category

  def self.lookup(item_code)
    where(:item_code => item_code).first
  end
end
```

### 1.2 Traditional mixins 

Mixing a module into a class using `include` makes that module's features
available to instances of that class. Unlike class-based inheritance, you
can mix in as many modules into a class as you'd like.

Perhaps the most commonly used module is `Enumerable`, which expects the
classes that use it to implement only a meaningful `each` method:

```ruby
class Order
  include Enumerable

  def initialize(products)
    @products = product
  end

  def each
    @products.each { |e| yield(e) }
  end

  def total_price
    reduce { |s,e| s + e.price }
  end
end
```

### 1.3 Per-object mixins

Modules can also be mixed in at the individual object level, via the `extend`
keyword. Per-object mixins have a higher precedence than modules mixed into
classes via `include`, but otherwise have similar semantics.

This method of code sharing has become increasingly common in Ruby, as a
convenient means of role-centric modeling:

```ruby
module Shopper
  def add_to_cart(product)
    cart << product
  end

  private

  def cart
    @cart ||= []
  end
end

# Usage:

current_user.extend(Shopper)
current_user.add_to_cart(product)
```

### 1.4 Decoration

Many different techniques exist for implementing the decorator 
pattern in Ruby. This method essentially involves adding new
functionality on a proxy object, and then delegating all other
messages to wrapped object. This kind of modeling can be hacked together
by hand using `method_missing`, or via higher level abstractions. 

The following example uses `DelegateClass` from Ruby's standard library:

```ruby
require "delegate"

class InternationalProduct < DelegateClass(Product)
  BASE_CURRENCY = "USD"

  def initialize(product, currency)
    @product  = product
    @currency = currency

    super(@product)
  end
  
  def price
    Currency.convert(@product.price, @currency, BASE_CURRENCY)
  end
end


# Usage:

product = InternationalProduct.new(Product.find(1337), "GBP")

p product.description # delegates to Product
p product.price       # uses InternationalProduct's definition
```

### 1.5 Simple composition

Composition-based code reuse is hard to describe, because it
is baked into the concept of an object. But we can easily
understand this style of modeling by constrasting it with
any another approach to code sharing.

Take for example the following object, which uses inheritance-based modeling:

```ruby
class SalesReport < Array
  def summary
    "Your order:\n\n" +
    map { |e| "* #{e.name}: #{e.price}" }.join("\n")
  end
end

# Usage:

Product = Struct.new(:name, :price)

hat     = Product.new("Hat",      500)
glasses = Product.new("Glasses", 1000)

puts SalesReport.new([hat, glasses]).summary
```

Here, `SalesReport` inherits from `Array` to save a few lines of code,
but that causes it to gain every single method of `Array` as part of
its API. If that functionality isn't required, an alternative would 
be to use composition instead:

```ruby
class SalesReport
  def initialize(products)
    @products = products
  end

  def summary
    "Your order:\n\n" +
    @products.map { |e| "* #{e.name}: #{e.price}" }.join("\n")
  end
end
```

### 1.6 Dynamically evaluated codeblocks

It is a common practice for Ruby libraries to wrap their functionality in
domain-specific interfaces. This kind of modeling involves evaluating
code blocks within the context of command objects that do various kinds of
magic under the hood.

The following FactoryGirl code is a typical example of this style of API: 

```ruby
FactoryGirl.define do
  factory :product do
    name          "Super crusher 5000"
    description   "The best product ever"
    price         500
  end
end

# ...

# build() returns a saved Product instance
product = FactoryGirl.build(:product) 

p product.price #=> 500
```

### 1.7 Monkey patching

The most direct way of sharing code in Ruby is to re-open a class definition and
continue to add functionality to it, but it is also the most invasive. This
approach is called monkey patching, and it is a widespread but controversial 
practice.

Syntactic sugar is often implemented via monkey patches, as in the code below:

```ruby
# NOTE: This is a terrible idea, don't actually do it!

class Numeric
  BASE_CURRENCY = "USD"

  def in_currency(target)
     Currency.new(self, BASE_CURRENCY, target)
  end
end

# usage
p 10.in_currency("GBP") #=> 6.36
```

## 2. Sources of design complexity

### 2.1 Late binding

Example: `Enumerable` module

### 2.2 Shared state

```ruby
require "ostruct"

class PrettyStruct < OpenStruct
  def inspect
    @table.map { |k,v| "#{k} = #{v.inspect}" }.join("\n")
  end
end

struct = PrettyStruct.new(:a => 3, :b => 4, :c => 5)
p struct

# a = 3
# b = 4
# c = 5
```

### 2.3 Shared public interface

ActiveRecord example? Or too boring?

### 2.4 Shared private interface

### 2.5 Shared ancestry chain

### 2.6 Self-schizophrenia

### 2.7 Dependency management

## 3. Notes and Recommendations

## 4. Further reading

Practicing Ruby "Criteria for DI"

DI
Liskov

Unobstrusive Ruby in Practice

(If comprehensive -- costs of inheritance / BrokenRecord stuff)

DSLs article?
