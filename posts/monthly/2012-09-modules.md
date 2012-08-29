## PART 1

Modules are part of what makes Ruby's design beautiful. However, since they do not have a direct analogy in any mainstream programming language, it is easy to get a bit confused about what they should be used for. While most folks quickly encounter at least some of their use cases, typically only very experienced Ruby developers know their true versatilty.

In this four part article series, I aim to demystify Ruby modules by showing many practical use cases, explaining some tricky details along the way. We'll work through some of the fundamentals in the first two issues, and move into more advanced examples in the second two. Today we'll kick off this series by looking at the most simple, but perhaps most important ability modules offer us, the creation of namespaces.

### Modules for Namespacing

Imagine that you are writing an XML generation library, and in it, you have a class to generate your XML documents. Perhaps uncreatively, you choose the name `Document` for your class, creating something similar to what is shown below.

```ruby
class Document
  def generate
    # ...
  end
end
```

On its own, this seems to make a lot of sense; a user could do something simple like the following to make use of your library.

```ruby
require "your_xml_lib"
document = Document.new
# do something with document
puts document.generate
```

But imagine that you were using another library that generates PDF documents, which happens to use similar uncreative naming for its class that does the PDF document generation. Then, the following code would look equally valid.

```ruby
require "their_pdf_lib"
document = Document.new
# do something with document
puts document.generate
```

As long as the two libraries were never loaded at the same time, there would be no issue. But as soon as someone loaded both libraries, some quite confusing behavior would happen. One might think that defining two different classes with the same name would lead to some sort of error being raised by Ruby, but with open classes, that is not the case. Ruby would actually apply the definitions of `Document` one after the other, with whatever file was required last taking precedence. The end result would in all likelihood be a very broken `Document` class that could generate neither XML nor PDF.

But there is no reason for this to happen, as long as both libraries take care to namespace things. Shown below is an example of two `Document` classes that could co-exist peacefully.

```ruby
# somewhere in your_xml_lib

module XML
  class Document
    # ...
  end
end

# somewhere in their_pdf_lib

module PDF
  class Document
    # ...
  end
end
```

Using both classes in the same application is as easy, as long as you explicitly include the namespace when referring to each library's `Document` class.

```ruby
require "your_xml_lib"
require "their_pdf_lib"

# this pair of calls refer to two completely different classes
pdf_document = PDF::Document.new
xml_document = XML::Document.new
```

The clash has been prevented because each library has nested its `Document` class within a module, allowing the class to be defined within that namespace rather than at the global level. While this is a relatively straightforward concept, it's important to note a few things about what is really going on here.

Firstly, namespacing actually applies to the way constants are looked up in Ruby in general, not classes in particular. This means that it applies to modules nested within modules as well as ordinary constants as well.

```ruby
module A
  module B
  end
end

p A::B

module A
  C = 10
end

p A::C
```

Secondly, this same behavior of using modules as namespaces applies just as well to classes, as in the code below.

```ruby
class Blog
  class Comment
    #...
  end
end
```

Be sure to note that in this example, nesting a class within a class does not in any way make it a subclass or establish any relationship between `Blog` and `Blog::Comment` except that `Blog::Comment` is within the `Blog` namespace. In the example below, you can see that a class nested within another class looks the same as a class nested within a module.

```ruby
blog = Blog.new
comment = Blog::Comment.new
# ...
```

Of course, this technique is only really useful when you have a desired namespace for your library that also happens matches one of your class names. In all other situations, it makes sense to use a module for namespacing as it would prevent your users from creating instances of an empty and meaningless class.

Finally, it is important to understand that constants are looked up from the innermost nesting to the outermost, finally searching the global namespace. This can be a bit confusing at times, especially when you consider some corner cases.

For example, examine the following code:

```ruby
module FancyReporter
  class Document
    def initialize
       @output = String.new
    end

    attr_reader :output
  end
end
```

If you load this code into irb and play with a bit on its own, you can inspect an instance of Document to see that its output attribute is a core ruby `String` object, as shown below:

```ruby
>> FancyReporter::Document.new.output
=> ""
>> FancyReporter::Document.new.output.class
=> String
```

While this seems fairly obvious, it is easy for a bit of unrelated code written elsewhere to change everything. Consider the following code:

```ruby
module FancyReporter
  module String
    class Formatter
    end
  end
end
```

While the designer of `FancyReporter` was most likely trying to be well organized by offering `FancyReporter::String::Formatter`, this small change causes headaches because it changes the meaning of `String.new` in `Document`'s initialize method. In fact, you cannot even create an instance of `Document` before the following error is raised:

```ruby
?> FancyReporter::Document.new
NoMethodError: undefined method `new' for FancyReporter::String:Module
	from (irb):35:in `initialize'
	from (irb):53:in `new'
	from (irb):53
```

There are a number of ways this problem can be avoided. Often times, it's
possible to come up with alternative names that do not clash with core objects,
and when that's the case, it's preferable. In this particular case, `String.new`
can also be replaced with `""`, as nothing can change what objects are created
via Ruby's string literal syntax. But there is also an approach that works
independent of context, and that is to use explicit constant lookups from the
global namespace. You can see an example of explicit lookups in the following
code:

```ruby
module FancyReporter
  class Document
    def initialize
       @output = ::String.new
    end

    attr_reader :output
  end
end
```

Prepending any constant with `::` will force Ruby to skip the nested namespaces and bubble all the way up to the root. In this sense, the difference between `A::B` and `::A::B` is that the former is a sort of relative lookup whereas the latter is absolute from the root namespace.

In general, having to use absolute lookups may be a sign that there is an unnecessary name conflict within your application. But if upon investigation you find names that inheritently collide with one another, you can use this tool to avoid any ambiguity in your code.

While we've mostly covered the mechanics of namespacing, all this talk about `::` compells me to share a cautionary tale of mass cargoculting before we wrap up for today. Please bear with me as I stroke my beard for a moment.

### Abusing the Constant Lookup Operator (`::`)

In some older documentation, and some relatively recent code written by folks who learned from old documentation, you may see class methods being called in the manner shown below.

```ruby
YAML::load(File::read("foo.yaml"))
```

While the above code runs fine, it's only a historical accident that it does. In fact, `::` was never meant for method invocation, class methods or otherwise. You can easily demonstrate that `::` can be used to execute instance methods as well, which eliminates any notion that `::` has some special 'class methods only' distinction to it.

```ruby  
"foo"::reverse #=> "oof"
```

As far as I can tell, this style of method invocation actually came about as a documentation convention. In both formal documentation and in mailing list discussions, it can sometimes be difficult to discern whether someone is talking about a class method or instance method, since both can be called just as well with the dot operator. So, a convention was invented so that for a class `Foo`, the instance method `bar` would be referred to as `Foo#bar`, and the class method `bar` would be referred to as `Foo::bar`. This did away with the dot entirely, leaving no room for ambiguity.

Unfortunately, this lead to a confusing situation. Beginners would often type `Foo#bar` to try to call instance methods, but were at least promptly punished for doing so because such code will not run at all. However, typing `Foo::bar` does work! Thus, an entire generation of Ruby developers were born thinking that `::` is some sort of special operator for calling class methods, and to an extent, others followed suit as a new convention emerged.

The fact that `::` will happily call methods for you has to do with internal implementation details of MRI, and so it's actually an undefined behavior, subject to change. As far as I know, there is no guarantee it will actually work as expected, and so it shouldn't be relied upon.

In your code, you should feel free to replace any method calls that use this style with ordinary `Foo.bar` calls. This actually reflects more of the true nature of Ruby, in that it doesn't emphasize the difference between class level calls and instance level calls, since that distinction isn't especially important. In documentation, things are a little trickier, but it is now generally accepted that `Foo.bar` refers to a class method and `Foo#bar` refers to an instance method. In cases where that distinction alone might be confusing, you could always be explicit, as in the example below.

```ruby
obj.bar # obj is an instance of Foo
```

If this argument wasn't convincing enough, you should know that every time you replace a `Foo::bar` call with `Foo.bar`, a brand new baby unicorn is born beneath a magnificent double rainbow. That should be reason enough to reverse this outdated practice, right?

### Reflections 

This article probably gave you more details than you ever cared to know about namespacing. But future articles will be sure to blow your mind with what else modules can do. However, if you have any questions or thoughts about what we've discussed so far, feel free to leave them in the comments section below.
  
> **NOTE:** This article has also been published on the Ruby Best Practices blog. There [may be additional commentary](http://blog.rubybestpractices.com/posts/gregory/037-issue-8-uses-for-modules.html#disqus_thread) 
over there worth taking a look at.

----------

## PART 2!!!

### Using Mix-ins to Augment Class Definitions

Although knowing [how to use modules for namespacing](http://practicingruby.com/articles/36) is important, it's really only a small part of what you can do with modules. What modules do best is providing a convenient way to write code that be mixed into other objects, augmenting their behaviors. Because modules facilitate code sharing in a way that is distinct from both the general OO concept of class inheritance and from things like Java's interfaces, they require you to think about your design in a way that's a bit different from most other object oriented programming languages.

While I imagine that most of our readers are comfortable with using mixins, I'll
refer to some core Ruby mixins to illustrate their power before moving on to more 
subtle points. For example, consider the following bit of code which implements lazily evaluated computations:

```ruby
class Computation

  def initialize(&block)
    @action = block
  end

  def result
    @result ||= @action.call
  end

  def <(other)
    result < other.result
  end

  def >(other)
    result > other.result
  end

  def >=(other)
    result >= other.result
  end

  def <=(other)
    result <= other.result
  end

  def ==(other)
    result == other.result
  end

end

a = Computation.new { 1 + 1 }
b = Computation.new { 4*5 }
c = Computation.new { -3 }

p a < b  #=> true
p a <= b #=> true
p b > c  #=> true
p b >= c #=> true
p a == b #=> false
```

While Ruby makes defining custom operators easy, there is a lot more code here than there needs to be. We can easily clean it up by mixing in Ruby's built in `Comparable` module.

```ruby
class Computation
  include Comparable

  def initialize(&block)
    @action = block
  end

  def result
    @result ||= @action.call
  end

  def <=>(other)
    return  0 if result == other.result
    return  1 if result > other.result
    return -1 if result < other.result
  end
end

a = Computation.new { 1 + 1 }
b = Computation.new { 4*5 }
c = Computation.new { -3 }

p a < b  #=> true
p a <= b #=> true
p b > c  #=> true
p b >= c #=> true
p a == b #=> false
```

We see that our individual operator definitions have disappeared, and in its place are two new bits of code. The first new thing is just an include statement that tells Ruby to mix the `Comparable` functionality into the `Computation` class definition. But in order to make use of the mixin, we need to tell `Comparable` how to evaluate the sort order of our `Computation` objects, and that's where `<=>` comes in.

The `<=>` method, sometimes called the spaceship operator, essentially fills in a template method that allows `Comparable` to work. It codifies the notion of comparison in an abstract manner by expecting the method to return `-1` when the current object is considered less than the object it is being compared to, `0` when the two are considered equal, and `1` when the current object is considered greater than the object it is being compared to.

If you're still scratching your head a bit, pretend that rather than being a core Ruby object, that we've implemented `Comparable` ourselves by writing the following code.

```ruby
module Comparable
  def ==(other)
    (self <=> other) == 0
  end

  def <(other)
    (self <=> other) == -1
  end

  def <=(other)
    self < other || self == other
  end

  def >(other)
    (self <=> other) == 1
  end

  def >=(other)
    self > other || self == other
  end
end
```

Now, if you imagine these method definitions literally getting pasted into your `Computation` class when `Comparable` is included, you'll see that it would provide a behavior that is functionally equivalent to our initial example.

Of course, it wouldn't make sense for Ruby to implement such a feature for us
without using it in its own structures. Because Ruby's numeric classes
all implement `<=>`, we are able to simply delegate our `<=>` call to the 
result of the computations.

```ruby
class Computation
  include Comparable

  def initialize(&block)
    @action = block
  end

  def result
    @result ||= @action.call
  end

  def <=>(other)
    result <=> other.result
  end
end
```

The only requirement for this code to work as expected is that each `Computation`'s result must implement the `<=>` method. Since all objects that mix in `Comparable` have to implement `<=>`, any comparable object returned as a result should work fine here.

While not a technically complicated example, there is surprising power in having a primitive built into your programming language which trivializes the implementation of the Template Method design pattern. If you look at Ruby's `Enumerable` module and the powerful features it offers, you might think it would be a much more complicated example to study. But it too hinges on Template Method and requires only an `each()` method to give you all sorts of complex functionality including things like `select()`, `map()`, and `inject()`. If you haven't tried it before, you should certainly try to roll your own `Enumerable` module to get a sense of just how useful mixins can be.

We can also invert this relationship by having our class define a template, and then relying on the module that we mix in to provide the necessary details. If we look back at an previous example `TicTacToe`, we can see a practical example of this technique by looking at the play method in our `TicTacToe::Game` class.

```ruby
module TicTacToe
  class Game
    def play
      catch(:finished) do
        loop do
          start_new_turn
          show_board

          check_move { |error_message| puts error_message }
          check_win { puts "#{current_player} wins" }
          check_draw { puts "It's a tie" }
        end
      end
    end

    # ...
  end
end
```

In this code, we wanted to keep our event loop abstract, and rely on a mixed in module to provide the logic for executing and validating a move as well as checking end game conditions. As a result, we ended up with the `TicTacToe::Rules` module shown below.

```ruby
module TicTacToe
  module Rules
    def check_move
      row, col = move_input
      board[row, col] = current_player
    rescue TicTacToe::Board::InvalidRequest => error
      yield error.message if block_given?
      retry
    end

    def check_win
      return false unless board.last_move

      win = board.intersecting_lines(*board.last_move).any? do |line|
        line.all? { |cell| cell == current_player }
      end

      if win
        yield
        game_over
      end
    end

    def check_draw
      if @board.covered?
        yield
        game_over
      end
    end
  end
end
```

When we look at this code, we see some basic business logic implementing the rules of Tic Tac Toe, with some placeholder hooks being provided by yield that allows the calling code to inject some logic at certain key points in the process. This is how we manage to split the UI code from the game logic, without creating frivolous adapter classes.

While this is amore complicated example than our walkthrough of `Comparable`, the two share a common thread. In both cases, some coupling exists between the module and the object it is being mixed into. This is a common pattern when using mixins, in which the module and the code it is mixed into have to do a bit of a secret handshake to be able to talk to one another, but as long as they agree on that, neither needs to know about the other's inner workings. The end result is two components which must agree on an interface but do not need to necessarily understand each other's implementations. Code with this sort of coupling is easy to test and easy to refactor.

### Using Mix-ins to Augment Objects Directly

As you may already know, Ruby's mixin capability is not limited to simply including new behavior into a class definition. You can also extend the behavior of a class itself, through the use of the `extend()` method. We can look to the Ruby standard library <i>forwardable</i> for a nice example of how this is used. Consider the following trivial `Stack` implementation.

```ruby
require "forwardable"

class Stack
  extend Forwardable

  def_delegators :@data, :push, :pop, :size, :first, :empty?

  def initialize
    @data = []
  end
end
```

In this example, we can see that after we extend our `Stack` class with the `Forwardable` module, we are provided with a class level method called `def_delegators` which allows us to easily define methods which delegate to an object stored in the specified instance variable. Playing around with the `Stack` object a bit should illustrate what this code has done for us.

```ruby
>> stack = Stack.new
=> #<Stack:0x4f09c @data=[]>
>> stack.push 1
=> [1]
>> stack.push 2
=> [1, 2]
>> stack.push 3
=> [1, 2, 3]
>> stack.size
=> 3
>> until stack.empty?
>>   p stack.pop
>> end
3
2
1
```

As before, it may be helpful to think about how we might implement `Forwardable` ourselves. The following bit of code shows one way to approach the problem.

```ruby
module MyForwardable
  def def_delegators(ivar, *delegated_methods)
    delegated_methods.each do |m|
      define_method(m) do |*a, &b|
        obj = instance_variable_get(ivar)
        obj.send(m,*a, &b)
      end
    end
  end
end
```

While the metaprogramming aspects of this may be a bit noisy to read if you're not familiar with them, this is fairly vanilla dynamic Ruby code. If you've got Ruby 1.9.2 installed, you can actually try it out on your own and verify that it does indeed work as expected. But the practical use case of this code isn't what's important here.

The key thing to notice about this code is that while it essentially implements a class method, nothing in the module's syntax directly indicates this to be the case. The only hint we get that this is meant to be used at the class level is the use of `define_method()`, but we need to dig into the implementation code to notice that.

Before we wrap up, we should investigate why this is the case.

### A Brief Stroking of the Beard

The key thing to recognize is that `include()` mixes methods into the instances of the base object while `extend()` mixes methods into the base object itself. Notice that this is more general than a class method / instance method dichotomy.

Let's explore a few differently possibilities using a somewhat contrived example so that we can focus on the mixin mechanics. First, we start with an ordinary module, which is somewhat useless on its own.

```ruby
module Greeter
  def hello
    "hi"
  end
end
```

By including `Greeter` into `SomeClass`, we make it so that we can now call `hello()` on instances of `SomeClass`.

```ruby
class SomeClass
  include Greeter
end

SomeClass.new.hello #=> "hi"
```

But as we saw in the `Forwardable` example, extending `AnotherClass` with `Greeter` would allow us to call the hello method directly at the class level, as in the example below.

```ruby
class AnotherClass
  extend Greeter
end

AnotherClass.hello #=> "hi"
```

Be sure to note at this point that `extend()` and `include()` are two totally
different operations. Because you did not extend `SomeClass` with `Greeter`, you
could not call `SomeClass.hello()`. Similarly, you cannot call
`AnotherClass.new.hello()` without explicitly including `Greeter`.

From the examples so far, it might seem as if `include()` is for defining instance methods, and `extend()` is for class methods. But that is not quite accurate, and the next bit of code illustrates just how much deeper the rabbit hole goes.

```ruby
obj = Object.new
obj.extend(Greeter)
obj.hello #=> "hi"
```

Before you let this example make you go cross-eyed, let's review the key point I made at the beginning of this section: <i>The key thing to recognize is that `include()` mixes methods into the instances of the base object while `extend()` mixes methods into the base object itself.</i>

Since not every base object can have instances, not every object can have modules included into them (in fact, only classes can). But *every* object can be extended by modules. This includes, among other things, classes and modules themselves.

Let's try to bring the two `extend()` examples closer together with the following little snippet:

```ruby
MyClass = Class.new
MyClass.extend(Greeter)
MyClass.hello #=> "hi"
```

If you feel like you understand the lines above, you're ready for the rest
of this mini-series. If not, please ponder the following questions and leave a
comment sharing your thoughts.

### Questions To Consider

  * Why do we have both `include()` and `extend()` available to us? Why not just have one way of doing mixins?

  * When you write `extend()` within a class definition, does it do any sort of special casing? Or is it the same as calling `extend()` on any other object?

  * Except for mixing in class methods, what is `extend()` useful for?

Please feel free to ask for hints on any of these if you're stumped, or share your answers if you'd like to help others and maybe get a bit of feedback to check your assumptions against.

  
> **NOTE:** This article has also been published on the Ruby Best Practices blog. There [may be additional commentary](http://blog.rubybestpractices.com/posts/gregory/038-issue-9-uses-for-modules.html#disqus_thread) 
over there worth taking a look at.

----

## PART 3

In the last two issues, we covered mixins and namespacing, two of the most common uses for modules. In the second half of this series, we'll look at some other ways to use modules that are not quite so obvious.

We can now focus on the question that caused me to write this series in the
first place. Many readers were confused by my use of `extend self` within
earlier Practicing Ruby articles, and this lead to a number of interesting
questions on the mailing list at the time these articles were originally
published. While I tried my best to answer them directly, I think we're in better
shape to study this topic now that the last two articles have laid a 
foundation for us.

### Review of how `extend()` works

To understand this trick of mixing modules into themselves, one first must understand how `extend()` works. We covered this concept at the end of the last article, but we can touch on it again for good measure. Start by considering the trivial module shown below.

```ruby
module Greeter
  def hello
    "hi"
  end
end 
```

We had shown that unlike `include()` which is especially designed for augmenting class definitions so that a mixin can add instance methods to some target class, `extend()` has a much more simple behavior and works with any object.

```ruby
obj = Object.new
obj.extend(Greeter)
obj.hello #=> "hi"
```

From this, we can see that mixing in a module by using extend simply mixes the methods defined by the module directly at that object's level. In this way, the methods defined by the module are mixed into the receiver, no matter what that object is.

In Ruby, classes and modules are ordinary objects. We can confirm this by doing a tiny bit of introspection on `Greeter`.

```ruby
>> Greeter.object_id
=> 212500
>> Greeter.class
=> Module
>> Greeter.respond_to?(:extend)
=> true
```

While this may be a mental leap for some, you might be able to find peace with it by considering the ordinary module definition syntax to be a bit of sugar that is functionally equivalent to the following bit of code.

```ruby  
Greeter = Module.new do
  def hello
    "hi"
  end
end
```

When written in this way, it becomes far more obvious that `Greeter` is actually just an instance of the class Module, making it an ordinary Ruby object at its core. Once you feel that you understand this point, consider what happens when the following line of code is run.

```ruby
Greeter.extend(Greeter)
```

If we compare this to previous examples of `extend()`, it should be clear now that despite the seemingly circular reference, this line does exactly what it would if called on any other object: It mixes the methods defined by `Greeter` directly into the `Greeter` object itself. A simple test confirms this to be true.

```ruby
Greeter.hello #=> "hi"
```

If we unravel things a bit, we find that we could have written our `extend()` call slightly differently, by doing it from within the module definition itself:

```ruby
module Greeter
  extend Greeter

  def hello
    "hi"
  end
end
```

The reason `extend()` works here is because `self == Greeter` in this context.
Noticing this detail allows us to use slightly more dynamic approach, resulting
in the following code.

```ruby
module Greeter
  extend self

  def hello
    "hi"
  end
end
```

You'll find this new code to be functionally identical to the previous example, but slightly more flexible. Now, if we change the name of our module, we won't need to update our `extend()` call. This is why folks tend to write `extend self` rather than `extend TheCurrentModule`.

Hopefully by now, it is clear that this trick does not involve any sort of special casing for modules, and is an ordinary application of the `extend()` method provided by every Ruby object. The only thing that might be confusing is the seemingly recursive nature of the technique, but this issue disappears when you recognize that modules are not mixed into anything by default, and that modules themselves are not directly related to the methods they define. If you understand the difference between class and instance methods in Ruby, this isn't a far stretch from that concept.

While the inner workings of modules are an interesting academic topic, my emphasis is always firmly set on practical applications of programming techniques rather than detached conceptual theory. So now that we've answered 'how does this work?', let's focus on the much more interesting 'how can I use it?' topic.

### Self-Mixins as Function Bags

A fascinating thing about Ruby is the wide range of different software design paradigms it supports. While object-oriented design is heavily favored, Ruby can do a surprisingly good job of emulating everything from procedure programming to prototype-based programming. But the one area that Ruby overlaps most with is functional programming.

Now, before you retire your parenthesis for good and herald Ruby as a replacement for LISP, be warned: There is a lot about Ruby's design that makes it a horrible language for functional programming. But when used sparingly, techniques from the functional world fit surprisingly well in Ruby programs. The technique I find most useful is the ability to organize related functions together under a single namespace.

When we create class definitions, we tend to think of the objects we're building as little structures which manage state and provide behaviors which manipulate that state. But sometimes, a more stateless model makes sense. The closer you get to pure mathematics, the more a pure functional model makes sense. We need to look no farther than Ruby's own `Math` module for an example:

```ruby
>> Math.sin(Math::PI/2.0)
=> 1.0
>> Math.log(Math::E)
=> 1.0
```

It seems unlikely that we'd want to create an instance of a `Math` object, since
it doesn't really deal with any state that persists beyond a single function
call. But it might be desirable to mix this functionality into another object so
that you can call math functions without repeating the `Math` constant
excessively. For this reason, Ruby implements `Math` as a module.

```ruby
>> Math.class
=> Module
```

For another great example of modular code design in Ruby itself, be sure to check out the `FileUtils` standard library, which allows you to basic *nix file operations as if they were just ordinary function calls.

After seeing how Ruby is using this technique, I didn't find it hard to stumble upon scenarios in my own code that could benefit from a similar design. For example, when I was working on building out the backend for a trivia website, I was given some logic for normalizing user input so that it could be compared against a predetermined pattern.

While I could have stuck this logic in a number of different places, I decided I wanted to put it within a module of its own, because its logic did not rely on any persistent state and could be defined independently of the way our questions and quizzes were modeled. The following code is what I came up with:

```ruby
module MinimalAnswer
  extend self

  def match?(pattern, input)
    pattern.split(/,/).any? do |e| 
      normalize(input) =~ /\b#{normalize(e)}/i 
    end
  end

  private

  def normalize(input)
    input.downcase.strip.gsub(/\s+/," ").gsub(/[?.!\-,:'"]/, '')
  end
end
```

The nice thing about the code above is that using a modular design doesn't force you to give up things like private methods. This allows you to keep your user facing API narrow while still being able to break things out into helper methods.

Here is a simple example of how my `MinimalAnswer` module is used within the application:

```ruby
>> MinimalAnswer.match?("Cop,Police Officer", "COP")
=> true
>> MinimalAnswer.match?("Cop,Police Officer", "police officer")
=> true
>> MinimalAnswer.match?("Cop,Police Officer", "police office")
=> false
>> MinimalAnswer.match?("Cop,Police Officer", "police officer.")
=> true
```

Now as I said before, this is a minor bit of functionality and could probably be shelved onto something like a `Question` object or somewhere else within the system. But the downside of that approach would be that as this `MinimalAnswer` logic began to get more complex, it would begin to stretch the scope of whatever object you attached this logic to. By breaking it out into a module right away, we give this code its own namespace to grow in, and also make it possible to test the logic in isolation, rather than trying to bootstrap a potentially much more complex object in order to test it.

So whenever you have a bit of logic that seems to not have many state dependencies between its functions, you might consider this approach. But since stateless code is rare in Ruby, you may wonder if learning about self-mixins really bought us that much.

As it turns out, the technique can also be used in more stateful scenarios when you recognize that Ruby modules are objects themselves, and like any object, can contain instance data.

### Self-Mixins for Implementing Singleton Pattern

Ruby overloads the term 'singleton object', so we need to be careful about terminology here. What I'm about to show you is how to use these self-mixed modules to implement something similar to the [Singleton design pattern](http://en.wikipedia.org/wiki/Singleton_pattern).

I've found in object design that objects typically need zero, one, or many instances. When an object doesn't really need to be instantiated at all because it has no data in common between its behaviors, the modular approach we just reviewed often works best. The vast majority of the remaining cases fall into ordinary class definitions which facilitate many instances. Virtually everything we model fits into this category, so it's not worth discussing in detail. However, there are some cases in which a single object is really all we need. In particular, configuration systems come to mind.

The following example shows a simple DSL I wrote for the trivia application I had mentioned earlier. It may look familiar, and that is because it appeared in our discussion on writing configuration systems some weeks ago. This time around, our focus will be on how this system actually works rather than what purpose it serves.

```ruby
AccessControl.configure do
  role "basic",
    :permissions => [:read_answers, :answer_questions]

  role "premium",
    :parent      => "basic",
    :permissions => [:hide_advertisements]

  role "manager",
    :parent      => "premium",
    :permissions => [:create_quizzes, :edit_quizzes]

  role "owner",
    :parent      => "manager",
    :permissions => [:edit_users, :deactivate_users]
end 
```

To implement code that allows the definitions above to be modeled internally, we need to consider how this system will be used. While it is easy to imagine roles shifting over time, getting added and removed as needed, it's hard to imagine what the utility of having more than one `AccessControl` object would be.

For this reason, it's safe to say that `AccessControl` configuration data is global information, and so does not need the data segregation that creating instances of a class provides.

By modeling `AccessControl` as a module rather than class, we end up with an object that we can store data on that can't be instantiated.

```ruby
module AccessControl
  extend self

  def configure(&block)
    instance_eval(&block)
  end

  def definitions
    @definitions ||= {}
  end

  # Role definition omitted, replace with a stub if you want to test
  # or refer to Practicing Ruby Issue #4
  def role(level, options={})
    definitions[level] = Role.new(level, options)
  end

  def roles_with_permission(permission)
    definitions.select { |k,v| v.allows?(permission) }.map { |k,_| k }
  end

  def [](level)
    definitions[level]
  end 
end
```

There are two minor points of potential confusion in this code worth discussing, the first is the use of `instance_eval` in `configure()`, and the second is that the `definitions()` method refers to instance variables. This is where we need to remind ourselves that the scope of methods defined by a module cannot be determined until it is mixed into something.

Once we recognize these key points, a bit of introspection shows us what is really going on.

```ruby
>> AccessControl.configure { "I am #{self.inspect}" }
=> "I am AccessControl"
>> AccessControl.instance_eval { "I am #{self.inspect}" }
=> "I am AccessControl"
>> AccessControl.instance_variables
=> ["@definitions"]
```

Since `AccessControl` is an ordinary Ruby object, it has ordinary instance variables and can make use of `instance_eval` just like any other object. The key difference here is that `AccessControl` is a module, not a class, and so cannot be used as a factory for creating more instances. In fact, calling `AccessControl.new` raises a `NoMethodError`.

In a traditional implementation of Singleton Pattern, you have a class which disables instantiation through the ordinary means, and creates a single instance that is accessible through the class method `instance()`. However, this seems a bit superfluous in a language in which classes are full blown objects, and so isn't necessary in Ruby.

For cases like the configuration system we've shown here, choosing to use this approach is reasonable. That having been said, the reason why I don't have another example that I can easily show you is that with the exception of this narrow application for configuration objects, I find it relatively rare to have a legitimate need for the Singleton Pattern. I'm sure if I thought long and hard on it, I could dig some other examples up, but upon looking at recent projects I find that variants of the above are all I use this technique for.

However, if you work with other people's code, it is likely that you'll run into someone implementing Singleton Pattern this way. Now, rather than scratching your head, you will have a solid understanding of how this technique works, and why someone might want to use it.

### Reflections

In Issue 11, we'll wrap up with some even more specialized uses for modules, showing how they can be used to build plugin systems as well as how they can be used as a replacement for monkey patching. But before we close the books on today's lesson, I'd like to share some thoughts that were rattling around in the back of my mind while I was preparing this article.

The techniques I've shown today can be useful in certain edge case scenarios
where an ordinary class definition might not be the best tool to use. In my own
code, I tend to use the first technique of creating function bags often but sparingly, 
and the second technique of building singleton objects rarely and typically only 
for configuration systems.

Upon reflection, I wonder to myself whether the upsides of these techniques outweigh the cost of explaining them. I don't really have a definitive answer to that question, but it's really something I think about often.

On the one hand, I feel that users of Ruby should have an ingrained understanding of its object system. After all, these are actually fairly straightforward techniques once you understand how things work under the hood. It's also true that you can't really claim to understand Ruby's object system without fully understanding these examples. Having a weak understanding of how Ruby's objects work is sure to rob you of the joy of working in Ruby, so for this reason, I feel like 'dumbing down' our code would be a bad thing.

On the other hand, I think that for the small gains yielded by using these techniques, we require those who are reading our code to understand a whole score of details that are unique to Ruby. When you consider that by changing a couple lines of code, you can have a design which is not much worse but is understandable by pretty much anyone who has programmed in an OO language before, it's certainly tempting to cater to the lowest common denominator.

But this sort of split-mindedness is inevitable in Ruby, and comes up in many scenarios. The truth of the matter is that it's going to take many more years before Ruby is truly understood by the programming community at large. But as more people dive deeper into Ruby, Ruby is starting to come into its own, and the mindset that things should be done as they are in other languages is not nearly as common as it was several years ago. For this reason, it's important to stop thinking of Ruby in terms of whatever language you've come from, and start thinking of it as its own thing. As soon as you do that, a whole range of possibilities open up.

At least, that's what I think. What about you?

  
> **NOTE:** This article has also been published on the Ruby Best Practices blog. There [may be additional commentary](http://blog.rubybestpractices.com/posts/gregory/040-issue-10-uses-for-modules.html#disqus_thread) 
over there worth taking a look at.

----

## PART 3.5

In the [last issue](http://practicingruby.com/articles/38), we discussed the use of `extend self` in great detail, but neglected to cover a pair of alternatives that seem on the surface to be functionally equivalent. While I don't want to spend too much time rehashing an old topic, I want to at least provide an example of each approach and comment on their quirks.

### Defining methods at the module level

Occasionally folks ask whether mixing a module into itself via `extend()` is equivalent to the code shown below.

```ruby
module Greeter
  def self.hello
    "hi"
  end
end
```

The short answer to that question is "no", but it is easy to see where the confusion comes from, because calling `Greeter.hello` does indeed work as expected. But the important distinction is that methods defined in this way are simply directly defined on the module itself and so cannot be mixed into anything at all. There is really very little difference between the above code and the example below.

```ruby  
obj = Object.new

def obj.hello
  "hi"
end
```

Consider our earlier example of Ruby's `Math` or `FileUtils` modules. With both of these modules, you can envision scenarios in which you would call the functions on the modules themselves. But there are also cases where using these modules as mixins would make a lot of sense. For example, Ruby itself ships with a math mode (-m) for irb which mixes in the `Math` module at the top level so you can call its functions directly.

```ruby
$ irb -m
>> sin(Math::PI/2)
=> 1.0
```

In the above example, if `sin()` were implemented by defining the method
directly on the `Math` module, there would be no way to mix it into anything.
While sometimes it might make sense to force a module to never be used as a
mixin, that use case is rare, and so little is gained by defining methods on
modules rather than using the `extend self` technique.

### Using `module_function`

Before people got in the habit of mixing modules into themselves, they often relied on a more specialized feature called `module_function` to accomplish the same goals.

```ruby
module Greeter
  module_function

  def hello
    "hi"
  end
end
```

This code allows the direct calling of `Greeter.hello`, and does not prevent
`Greeter` from being mixed into other objects. The `module_function` approach
also allows you to choose certain methods to be module functions while 
leaving others accessible via mixin only:

```ruby
module Greeter
  def hello
    "hi"
  end

  def goodbye
    "bye"
  end

  module_function :hello
end
```

With this modified definition, it is still possible to call `Greeter.hello`, but attempting to call `Greeter.goodbye` would raise a `NoMethodError`. This sort of sounds like it offers the benefits of extending a module with itself, but with some added granularity. Unfortunately, there is something about `module_function` that makes it quite weird to work with.

As it turns out, `module_function` works very different under the hood than self-mixins do. This is because `module_function` actually doesn't manipulate the method lookup path, but instead, it makes a direct copy of the specified methods and attaches them to the module itself. If that sounds too weird to be true, check out the code below.

```ruby 
module Greeter
  def hello
    "hi"
  end

  module_function :hello

  def hello
    "howdy"
  end
end

Greeter.hello #=> "hi"

class Foo
  include Greeter
end

Foo.new.hello #=> "howdy"
```

Pretty weird behavior, right? You may find it interesting to know that I was not actually aware that `module_function` made copies of methods until I wrote Issue #10 and was tipped off about this by one of our readers. However, I did know about one of the consequences of `module_function` being implemented in this way: private methods cannot be used in conjunction with `module_function`. That means that the following example cannot be literally translated to use `module_function`.

```ruby
module MinimalAnswer
  extend self

  def match?(pattern, input)
    pattern.split(/,/).any? do |e|
      normalize(input) =~ /\b#{normalize(e)}/i
    end
  end

  private

  def normalize(input)
    input.downcase.strip.gsub(/\s+/," ").gsub(/[?.!\-,:'"]/, '')
  end
end 
```

From these examples, we see that `module_function` is more flexible than defining methods directly on your modules, but not nearly as versatile as extending a module with itself. While the ability to selectively define which methods can be called directly on the module is nice in theory, I've yet to see a use case for it where it would lead to a much better design.

### Reflections

With the alternatives to `extend self` having unpleasant quirks, it's no surprise that they're quickly falling out of fashion in the Ruby world. But since no technical decision should be made based on dogma or a blind-faith acceptance of community conventions, these notes hopefully provide the necessary evidence to help you make good design decisions on your own.

  
> **NOTE:** This article has also been published on the Ruby Best Practices blog. There [may be additional commentary](http://blog.rubybestpractices.com/posts/gregory/041-issue-10.5-uses-for-modules.html#disqus_thread) 
over there worth taking a look at.

-------

## PART 4

Today we're going to wrap up this series on modules by looking at how mixins can be useful for implementing custom behavior on individual objects. In particular, we'll be looking at how modules can be used both as a replacement for monkey patching, as well as for constructing systems that can be extended without the need for monkey patching. While neither of these techniques are going to be something you'll use every day, they really come in handy when you run into a situation that calls for them.

### Modules instead of Monkey Patches

Back in the bad old days before Prawn, I was working on a reporting framework called Ruby Reports (Ruport), which generated PDF reports via `PDF::Writer`. At the time, `PDF::Writer` was quite buggy, and essentially abandoned, but was the only game in town when it came to PDF generation.

One of the bugs was something fairly critical: Memory consumption for outputting simple PDF tables would balloon like crazy, causing a document with more than a few pages to take anywhere from several minutes to several *hours* to run.

The original author of the library had a patch laying around that inserted a hook which did some caching that greatly reduced the memory consumption, but he had not tested it extensively and did not want to want to cut a release. I had talked to him about possibly monkey patching `PDF::Document` in Ruport's code to add this patch, but together, we came up with a better solution: wrap the patch in a module.

```ruby
module PDFWriterMemoryPatch
  unless self.class.instance_methods.include?("_post_transaction_rewind")
    def _post_transaction_rewind
      @objects.each { |e| e.instance_variable_set(:@parent,self) }
    end
  end
end
```

In Ruport's PDF formatter code, we did something like the following to apply our patch:

```ruby
@document = PDF::Document.new
@document.extend(Ruport::PDFWriterMemoryPatch)
```

Throughout our application, whenever someone interacted with a `PDF::Document` instance we created, they had a patched instance that fixed the memory leak. This meant from the Ruport user's perspective, the bug was fixed. So what makes this different from monkey patching?

Because we were only manipulating the individual objects that we created in our library, we were not making a global change that might surprise people. For example if someone was building an application that only implicitly loaded Ruport as a dependency, and they created a `PDF::Document` instance, our patch would not be loaded. This prevented us from causing unexpected behavior in any code that lived outside of Ruport itself.

While this approach didn't shield us from the risks that a future change to `PDF::Writer` could potentially break our patch in Ruport, it did prevent any risk of global consequences. Anyone who's ever spent a day scratching their head because of some sloppy monkey patch in a third party dependency will immediately be able to see the value of this sort of isolation.

The neat thing is that a similar approach can be used for core extensions as
well. Rather than re-opening Ruby core classes, you can imbue individual
instances with custom behavior, getting many of the benefits of monkey patching
without the disadvantages. For example, suppose you want to add the `sum)()` and
`average()` methods to Array. If we were monkey patching, we'd write something
like the following code:

```ruby
class Array
  def sum
    inject(0) { |s,e| s + e }
  end

  def average
    sum.to_f / length
  end
end

obj = [1,3,5,7]
obj.sum     #=> 16
obj.average #=> 4
```

The danger here of course is that you'd be globally stomping anyone else's definition of `sum()` and `average()`, which can lead to ugly conflicts. All these problems can be avoided with a minor modification.

```ruby
module ArrayMathHelpers
  def sum
    inject(0) { |s,e| s + e }
  end

  def average
    sum.to_f / length
  end
end

obj = [1,3,5,7]
obj.extend(ArrayMathHelpers)
obj.sum     #=> 16
obj.average #=> 4
```

By explicitly mixing in the `ArrayMathHelpers` module, we isolate our changes just to the objects we've created ourselves. With slight modification, this technique can also be used with objects passed into functions, typically by making a copy of the object before working on it.

Because modules mixed into an instance of an object are looked up before 
the methods defined by its class, 
you can actually use this technique for modifying existing behavior of an object as well. 
The example below demonstrates modifying `<<` on strings so that it allows appending 
arbitrary objects to a string through coercion.

```ruby
module LooseStringAppend
  def <<(value)
    super
  rescue TypeError
    super(value.to_s)
  end
end

a = "foo"
a.extend(LooseStringAppend)
a << :bar << :baz #=> "foobarbaz"
```

Of course this (like most core modifications), is a horrible idea. But speaking as a pure technique, this is far better than the alternative global monkey patch shown below:

```ruby
class String
  alias_method :old_append, :<<
  
  def <<(value)
    old_append(value)
  rescue TypeError
    old_append(value.to_s)
  end
end
```

When using per-object mixins as an alternative to monkey patching, what you gain is essentially two things: A first class seat in the lookup path allowing you to make use of `super()`, and isolation on a per-object behavior so that consumers of your code don't curse you for patching things in unexpected ways. While this approach isn't always available, it is definitely preferable whenever you can choose it over monkey patching.

In Ruby 2.0, we may end up with even better option for this sort of thing called refinements, which are also module based. But for now, if you must hack other people's objects, this approach is a civil way to do it.

We'll now take a look at how to produce libraries and applications that actively encourage extensions to be done this way.

### Modules as Extension Points

This last section is not so much about practical advice as it is about taking what we've learned so far and really stretching it as far as possible into new territories. In essence, what follows are my own experiments with ideas that I'm not fully sure are good, but find interesting enough to share with you.

In previous Practicing Ruby issues, I've shown some code from a command line client we've used for time tracking in my consulting work. The tool itself never quite matured far enough to be release ready, but I used it as a testing ground for new design ideas, so it is a good conversation starter at least.

Today, I want to show how we implemented commands for it. Essentially, I want to walk through what happens when someone types the following command into their console:

```ruby
$ turbine start
Timer started at Wed Dec 15 17:55:37 -0500 2010
```

Because we knew this tool would evolve over time, we wanted to make it as hackable as possible. To do this, we set up a system in which commands get installed into a hidden folder in each project, making it trivial to modify existing commands or add new ones. Here's a quick directory listing to show what that structure looks like:

```ruby
$ ls .turbine/commands/standard/
add.rb		project.rb	rewind.rb	status.rb commit.rb push.rb		
staged.rb	stop.rb drop.rb	reset.rb start.rb
```

As you might expect, start.rb defines the start command. Here's what its source
looks like:

```ruby
Turbine::Application.extension(:start_command) do
  def start
    timer = Turbine::Timer.new
    if timer.running?
      prompt.say "Timer already started, please stop or rewind first"
    else
      timer.write_timestamp
      prompt.say "Timer started at #{Time.now}"
    end
  end
end
```

You'll notice that all our commands are direct mappings to method
calls, which are responsible for doing all the work. While I've simplified the
following definition to remove some domain specific callbacks and options 
parsing, the following example shows the basic harness which registers 
Turbine's commands:

```ruby
module Turbine
  class Application
    def self.extensions
      @extensions ||= {}
    end

    def self.extension(key, &block)
      extensions[key] = Module.new(&block)
    end

    def initialize
      self.class.extensions.each do |_, extension|
        extend(extension)
      end
    end
  
    def run(command)
      send(command)
    end
  end
end
```

From this, we see that `Turbine::Application` stores a Hash of anonymous modules
which are created on the fly whenever the `extension()` is called. The
interesting thing about this design is that the commands aren't applied globally
to `Turbine::Application`, but instead, are mixed in at the instance level. This
approach allows us to selectively disable features, or completely replace them 
with alternative implementations.

For example, consider a custom command that gets loaded after the standard commands, which is implemented like this:

```ruby
Turbine::Application.extension(:start_command) do
  def go
    puts "Let's go!"
  end
end
```

Because the module defining the `go()` method would replace the original module in the extensions hash, the original module ends up getting completely wiped out. In retrospect, for my particular use case, this approach seems to be like using a thermonuclear weapon where a slingshot would do, but you can't argue that this fails to take extensibility to whole new limits.

Eventually, when someone falls off the deep end in their study of modules, they ask 'is it possible to uninclude them?', and the short answer to that question is "No", promptly followed up with "Why would you want to do that?". But what we've shown here is a good approximation for unincluding a module, even if we haven't quite figured out the answer to the 'why' part yet.

But sometimes, we have to explore just for the fun of it, right? :)

### Reflections

I have had a blast writing to you all about modules and answering your questions as they come up. Unfortunately, the topic is even bigger than I thought, and there are at least two full articles I could write on the topic,which might actually be more practical and immediately relevant than the materials I've shared today. In particular, we didn't cover things like the `included()` and `extended()` hooks, which can be quite useful and are worth investigating on your own.

Moving forward, my goals for Practicing Ruby are to be able to hit a wide range of topics, so we'll probably move away from the fundamentals of Ruby's object system and go back to some more problem-solving oriented topics in the coming weeks. But if you like this kind of format, please let me know.

  
> **NOTE:** This article has also been published on the Ruby Best Practices blog. There [may be additional commentary](http://blog.rubybestpractices.com/posts/gregory/043-issue-11-uses-for-modules.html#disqus_thread) 
over there worth taking a look at.

