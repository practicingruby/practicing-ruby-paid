class Rectangle
  def area
    width * height
  end

  attr_accessor :width, :height
end

=begin
# incompatibility

class Square < Rectangle
end

square = Square.new 
square.width = 15
square.height = 10

p square.width  #=> 15
p square.height #=> 10 
=end

# definitional compatibility
class Square < Rectangle
  attr_accessor :size

  alias_method :width,  :size
  alias_method :height, :size

  def width=(size)
    self.size = size
  end

  def height=(size)
    self.size = size
  end
end

=begin
square = Square.new
square.width  = 10
square.height = 15

p square.width  #=> 15
p square.height #=> 15 
=end

def assert_area(area, rect)
  fail "Invalid area calculation" unless area == rect.width * rect.height
end

rect = Rectangle.new
rect.width  = 10
rect.height = 15

# will fail if rect swapped with square
assert_area(150, rect)
