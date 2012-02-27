
ContainerFullError  = Class.new(StandardError)
ContainerEmptyError = Class.new(StandardError)

require "set"

class Bag  
  def ==(other)
    [Set.new(data), limit] == [Set.new(other.send(:data)), other.send(:limit)]
  end

  # returns true if the collection is an ordered collection,
  # false otherwise. This defaults to returning false, but 
  # may be overridden by subtypes to return either true or false.
  def ordered?
    false
  end

  private
  
  attr_accessor :data, :limit
end

class Stack
  # other code similar to before

  def ordered?
    true
  end

  # use of send() is ugly here but I don't like making data public
  def ==(other)
    if other.ordered?
      [other.send(:data), other.send(:limit)] == [data, limit]
    else
      [Set[*other.send(:data)], other.send(:limit)] == [Set[*data], limit]
    end
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
b = Stack.new(3)
c = Stack.new(3)

p a == b

b.push(10)
b.push(15)

a.push(15)

p a == b

a.push(10)

p a == b

c.push(15)
c.push(10)

p a == c
p b == c
