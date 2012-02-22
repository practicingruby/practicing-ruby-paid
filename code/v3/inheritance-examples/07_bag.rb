
ContainerFullError  = Class.new(StandardError)
ContainerEmptyError = Class.new(StandardError)


# Uses stack terminology for convenience, but having aliased methods in Stack
# would be acceptable too.

require "set"

class Bag
  # other code similar to before

  def ==(other)
    [Set.new(data), limit] == [Set.new(other.data), other.limit]
  end

  protected 
  
  # NOTE: Implementing == is one of the few legitimate uses of 
  # protected methods / attributes
  attr_accessor :data, :limit
end


# Stack is a constrained sub-type of Bag,
# it will work as a stand-in for Bag,
# just with more specific behavior.

class Stack
  def initialize(limit)
    self.data  = []
    self.limit = limit
  end

  def push(obj)
    raise ContainerFullError unless data.length < limit

    data.push(obj)
  end

  def pop
    raise ContainerEmptyError if data.empty?

    data.pop
  end

  def include?(obj)
    data.include?(obj)
  end

  private

  attr_accessor :data, :limit
end

# Introducing an equals method creates a complicated problem...
# If bag over-specifies it, it limits the kind of subtypes that
# can be supported. If it underspecifies it, then Stack is left
# either implementing an incorrect ==, or having two kinds of ==.
# Could possibly add an ordered? to Bag with a tautological 
# constraint.
#
# # returns true or false dependening on whether the data is ordered.
# # default implementation returns false, but sub-types will typically
# # redefine this operation.
# def ordered?
#   false
# end
#

a = Bag.new(3)
b = Bag.new(3)

a == b

b.push(10)
b.push(15)
b.push(22)

p b.include?(20) #=> false
p b.include?(22) #=> true

p b.pop
p b.pop
p b.pop
