# Immutability combined with "programming by difference"
# improve this situation. 


=begin
# IF YOU WANT TO BE PENDANTIC...

require "forwardable"

class RectangularShape
  extend Forwardable

  delegate [:width, :height] => :shape

  def initialize(shape)
    self.shape = shape
  end

  def area
    width * height
  end

  private

  attr_accessor :shape
end
=end

module Rectangular
  def area
    width * height
  end
end

class Rectangle
  include Rectangular

  def initialize(width, height)
    self.width  = width
    self.height = height
  end

  attr_reader :width, :height

  private

  attr_writer :width, :height
end

class Square 
  include Rectangular

  def initialize(size)
    self.size = size
  end

  attr_reader  :size

  alias_method :width,  :size
  alias_method :height, :size

  private

  attr_writer :size
end

def assert_area(expected_area, rect)
  fail "Invalid area calculation" unless expected_area == rect.area
end

#rect   = Rectangle.new(10, 15)

# assertion will still pass when the following line is used instead.
#rect   = Square.new(15)

=begin
shape  = RectangularShape.new(rect)

p shape.width
p shape.height
=end

assert_area(rect.width * rect.height, rect)
