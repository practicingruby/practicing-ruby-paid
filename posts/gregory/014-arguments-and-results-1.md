Back in 1997, James Noble published a paper called [Arguments and Results](http://www.laputan.org/pub/patterns/noble/noble.pdf) which outlined several useful patterns for designing better object protocols. Despite the fact that this paper was written nearly 15 years ago, it addresses design problems that programmers still struggle with today. In this two part article, I will show how the patterns James came up with can be applied to modern Ruby programs.

_Arguments and Results_ is written in such a way that it is natural to split the patterns it describes into two separate groups: patterns about method arguments and patterns about the results returned by methods. I've decided to split this Practicing Ruby article in the same manner in order to make it easier for me to write and easier for you to read. 

In this first installment, we will explore the patterns James lays out for working with method arguments, and in Issue 2.15 we'll look into results objects. If you read this part, be sure to read the second part once it comes out, because the two concepts compliment each other nicely.

### Establishing a context 

It is very difficult to study design patterns without applying them within a particular context. When I am trying to learn new patterns, I look for a scenario that the pattern might be applicable to and then examine the benefits and drawbacks of the design changes within that context. James uses a lot of graphics programming examples in his paper and this is for good reason: it's an area where designing good interfaces for your objects can easily get unwieldy.

I've decided to follow in James's footsteps here and use a trivial [SVG](http://www.w3.org/TR/SVG/) generator as the common theme for the examples in this article. The following code illustrates the interface that I started with before applying any special patterns:

```ruby
# image dimensions are provided to `Drawing` in cm, 
# all other measurements are done in units of 0.01 cm

drawing = Drawing.new(4,4)

drawing.line(:x1 => 100, :y1 => 100, :x2 => 200, :y2 => 250,
             :stroke_color => "blue", :stroke_width => 2)

drawing.line(:x1 => 300, :y1 => 100, :x2 => 200, :y2 => 250,
             :stroke_color => "blue", :stroke_width => 2)

File.write("sample.svg", drawing.to_svg)
```

The implementation details are not important here, but if you would like to see how this code works, you can check out the [source code for the Drawing class](https://github.com/elm-city-craftworks/pr-arguments-and-results/blob/7656768680b6a940a5ccf569fc0e0dce48a5dbfe/drawing.rb). The interface for `Drawing#line` uses keyword-style arguments in a similar fashion to most other Ruby libraries. Because keyword arguments are easier to remember and more flexible than ordinal arguments, this style of interface has become very popular among Ruby programmers. However, the more arguments a method takes, the more unwieldy this sort of API becomes. That tipping point is where design patterns about arguments come into play.

### Arguments object

As the number of arguments to a method increase, the amount of code within the method to handle those arguments tends to increase as well. This is because complex protocols typically require  arguments to be validated and transformed before they can be operated on. By introducing new objects to wrap related sets of arguments, it is possible to keep your argument processing logic somewhat separated from your business logic. The following code demonstrates how to use this concept to simplify the interface of the `Drawing#line` method:

```ruby
drawing = Drawing.new(4,4)

line1 = Drawing::Shape.new([100, 100], [200, 250])
line2 = Drawing::Shape.new([300, 100], [200, 250])

line_style = Drawing::Style.new(:stroke_color => "blue", :stroke_width => "2")

drawing.line(line1, line_style)

drawing.line(line2, line_style)

File.write("sample.svg", drawing.to_svg)
```

This approach takes a single complex method call on a single object and replaces it with several less complex method calls distributed across several objects. In the early stages of development, applying this pattern feels ugly because it involves writing a lot more code for both the library developer and application developer. However, as the complexity of the argument processing increases, the benefits of this approach begin to shine. The following example demonstrates how the newly introduced arguments objects raise the `Drawing#line` code up to a higher level of abstraction.

```ruby
def line(data, style)
  unless data.bounded_by?(@viewbox_width, @viewbox_height)
    raise ArgumentError, "shape is not within view box"
  end

  @lines << { :x1 => data[0].x.to_s, :y1 => data[0].y.to_s,
              :x2 => data[1].x.to_s, :y2 => data[1].y.to_s,
              :style => style.to_css }
end
```

The cost of making `Drawing#line` so concise is a big chunk of boilerplate code that on the surface feels a bit overkill at this stage in the game. However, it does not take a very wild imagination to see how these new objects set the stage for future extensions:

```ruby
class Point
  def initialize(x, y)
    @x, @y = x, y
  end

  attr_reader :x, :y
end

class Shape
  def initialize(*point_data)
    @points = point_data.map { |e| Point.new(*e) }
  end

  def [](index)
    @points[index]
  end

  def bounded_by?(x_max, y_max)
    @points.all? { |p| p.x <= x_max && p.y <= y_max }
  end
end

class Style
  def initialize(params)
    @stroke_width  = params.fetch(:stroke_width, 5)
    @stroke_color  = params.fetch(:stroke_color, "black")
  end

  attr_reader :stroke_width, :stroke_color

  def to_css
    "stroke: #{@stroke_color}; stroke-width: #{@stroke_width}"
  end
end
```

The interesting thing about these objects is that they actually represent domain models even though their original purpose was simply to wrap up some arguments to a single method the `Drawing` object. James mentions in his paper that this phenomena is common and would call these "Found objects", i.e. objects that are part of the domain model that were found through refactoring rather than accounted for in the original design.

You might have noticed that in the previous example, I set some default values for some of the variables on the `Style` object. If you compare this to setting defaults directly within the `Drawing#line` method itself, it becomes obvious that there is a benefit here. Properties like
the color and thickness of the lines drawn to form a shape are universal properties, not things specific to straight lines only. Centralizing the defaults makes it so that they do not need to be repeated for each new type of shape add support for in our `Drawing` object.

### Selector object

Sometimes we end up with objects that have many methods that take similar arguments. While these methods may actually do different things, the only difference in the object protocol is the name of the message being sent. After adding method for rendering polygons to my `Drawing` object, I ended up in exactly this situation. The following example shows just how similar the `Drawing#line` interface is to the newly created `Drawing#polygon` method:

```ruby
drawing = Drawing.new(4,4)

line1 = Drawing::Shape.new([100, 100], [200, 250])
line2 = Drawing::Shape.new([300, 100], [200, 250])

triangle = Drawing::Shape.new([350, 150], [250, 300], [150,150])

style = Drawing::Style.new(:stroke_color => "blue", :stroke_width => 2)

drawing.line(line1, style)

drawing.line(line2, style)

drawing.polygon(triangle, style)

File.write("sample.svg", drawing.to_svg)
```

Taking a look at the implementation of both methods, it is easy to see that there are deep similarities in structure between the two:

```ruby
class Drawing
  # NOTE: other code omitted, not important...

  def line(data, style)
    unless data.bounded_by?(@viewbox_width, @viewbox_height)
      raise ArgumentError, "shape is not within view box"
    end

    @elements << [:line, { :x1    => data[0].x.to_s, 
                           :y1    => data[0].y.to_s, 
                           :x2    => data[1].x.to_s, 
                           :y2    => data[1].y.to_s,
                           :style => style.to_css }] 
  end

  def polygon(data, style)
    unless data.bounded_by?(@viewbox_width, @viewbox_height)
       raise ArgumentError, "shape is not within view box"     
    end

    @elements << [:polygon, { 
      :points => data.each.map { |point| "#{point.x},#{point.y}" }.join(" "),
      :style  => style.to_css
    }]
  end
end
```

To make this code more DRY, James recommends converting our arguments object into what he calls a selector object. A selector object is an object which uses similar arguments to do different things depending on the type of message it is meant to represent. James recommends using double dispatch or multi-methods to implement this pattern, but that approach is less convenient in Ruby because the language does not provide built-in semantics for function overloading. The good news is that he also mentions that inheritance can be used as an alternative, and in this case it was a perfect fit.

To simplify and clean up the previous example, I introduced `Line` and `Polygon` which inherit from `Shape`. I then combined the `Drawing#line` method and `Drawing#polygon` method into a single method called `Drawing#draw`. The following example demonstrates what the API ended up looking like as a result of this change:

```ruby
drawing = Drawing.new(4,4)

line1 = Drawing::Line.new([100, 100], [200, 250])
line2 = Drawing::Line.new([300, 100], [200, 250])

triangle = Drawing::Polygon.new([350, 150], [250, 300], [150,150])

style = Drawing::Style.new(:stroke_color => "blue", :stroke_width => 2)

drawing.draw(line1, style)
drawing.draw(line2, style)
drawing.draw(triangle, style)

File.write("sample.svg", drawing.to_svg)
```

The changes to the API are small but make the code a lot easier to read. This rearrangement introduces even more objects into the system, but simplifies the protocol between those objects. In large systems, this leads to greater maintainability and learnability at the cost of having a few more moving parts.



### Curried object


### Reflections


