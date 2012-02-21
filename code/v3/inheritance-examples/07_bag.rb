
# Uses stack terminology for convenience, but having aliased methods in Stack
# would be acceptable too.

class Bag
  def initialize
    self.data = [] 
  end

  def push(obj)
    data << obj
  end

  def pop
    data.shuffle!.pop  
  end

  private

  attr_accessor :data
end


# Stack is a constrained sub-type of Bag,
# it will work as a stand-in for Bag,
# just with more specific behavior.

class Stack
  def initialize
    self.data = []
  end

  def push(obj)
    data.push(obj)
  end

  def pop
    data.pop
  end

  private

  attr_accessor :data
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

b = Bag.new
b.push(10)
b.push(15)
b.push(22)

p b.pop
p b.pop
p b.pop
