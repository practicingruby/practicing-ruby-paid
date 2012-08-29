[[[ Consider adding a set of exercises at the end of the article, based on the
questions from the original issues ]]]

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

The clash has been prevented because each library has nested its `Document` class within a module, allowing the class to be defined within that namespace rather than at the global level.

[[[ consider talking about nesting any kind of constant + private constants,
consider replacing following section with Rack::File example as it is more
real]]]


Tt is important to understand that constants are looked up from the innermost nesting to the outermost, finally searching the global namespace. This can be a bit confusing at times, especially when you consider some corner cases.

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

[[[ fix abrupt cut here]]]

### Using Mix-ins to Augment Objects Directly

[[[ Consider replacing or recasting this section in a DCI context, reread and revise ]]]

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

[[[ Fix abrupt cut here ]]]

We can now focus on the question that caused me to write this series in the
first place. Many readers were confused by my use of `extend self` within
earlier Practicing Ruby articles, and this lead to a number of interesting
questions on the mailing list at the time these articles were originally
published. While I tried my best to answer them directly, I think we're in better
shape to study this topic now that the last two articles have laid a 
foundation for us.

### Self-Mixins as Function Bags

[[[ Think about extend self here vs module_function and def self.foo ]]]

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

[[[ Consider changing this to be a brief summary and forward reference to my
Singletons article ]]]

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

[[[ CONSIDER A REFINEMENTS EXAMPLE HERE, REWRITING THE PREVIOUS EXAMPLES W.
REFINEMENTS ]]]

### Modules as Extension Points

[[[ THE BASIC IDEAS HERE FORM A GOOD DCI-INSPIRED SCENARIO, BUT CONSIDER MORE
MODERN EXAMPLES ]]]

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
