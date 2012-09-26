s developers, we spend a lot of our time thinking about internal software 
quality, because it has such a strong influence on our productivity. We seek to
write code that is maintainable and easy to change, because if we do not, our 
work becomes very frustrating in a hurry. There is no need for an external
motivator to improve our own code quality, because if we fail to do so,
we are the ones to suffer the consequences.

The external quality of our software is often a different story. If we don't
have regular and close contact with the people who use our software, it takes a
lot of effort to imagine what kind of problems they might encounter as they
interact with our systems. In that sense, writing software that is highly 
usable and pleasant to work with is not something that comes naturally, but 
instead something that needs to be specifically designed for.

In this article, we will explore the problem of building highly usable systems
by considering the [principles for good design][principles] that were
established by Dieter Rams. Even though Rams did not design any software
himself (he gained his notoriety through his work on household goods for Braun 
in the 1960s), his ideas are perfectly relevant to modern software 
development, even when it comes to the design of open source development 
tools and libraries. 

To illustrate the universal nature of these design principles, I've
intentionally focused on the low-level tools that I use day to day when building
software in Ruby. My hope is that by seeing how each of the humanizing values that
Dieter Rams specified can be applied in even the most technical context, you will
be able to make use of them pretty much anywhere.

### Good design is innovative

> The possibilities for innovation are not, by any means, exhausted.
> Technological development is always offering new opportunities for innovative
> design. But innovative design always develops in tandem with innovative
> technology, and can never be an end in itself.

Celluloid

### Good design makes a product useful

>  A product is bought to be used. It has to satisfy certain criteria, not only
>  functional, but also psychological and aesthetic. Good design emphasizes the
>  usefulness of a product whilst disregarding anything that could possibly
>  detract from it.

Nokogiri

### Good design is aesthetic

>  The aesthetic quality of a product is integral to its usefulness because
>  products are used every day and have an effect on people and their
>  well-being. Only well-executed objects can be beautiful.

Aesthetics play a big role in software design, to the extent that we
even talk about abstract snippets of code as being beautiful or ugly, depending
on how they are crafted. While this kind of intuitive judgement of code quality
can be a very useful heuristic, it is also very subjective and hard to
generalize. As a result, it is not uncommon for mutually exclusive but equally
valid style preferences to cause tensions between programmers.

While the grail quest for discovering the optimal coding style is a bit of a
dead end, there are less controversial ways that aesthetics can be applied to
programming. If you take a step down the [ladder of
abstraction][ladder] from code itself to the interface it presents to the world, it
becomes easier to see how aesthetic qualities affect the overall experience of
interacting with any given software system. The [SimpleCov][SimpleCov] test
coverage tool provides an excellent example of how these ideas can be applied
in practice.

Like any coverage tool, the core job of SimpleCov is to provide reports that
show developers what areas of their code are not being executed by their test
suite. This information is useful at both the line-by-line and project-wide
level, as well as in many contexts that lie between those two extremes. This
is a surprisingly complicated data presentation problem, but SimpleCov lives up
to its name and manages to keep things simple without sacrificing visual
attractiveness.

```ruby
require "simplecov"

SimpleCov.start "rails"
```


- Test coverage reports are both an aggregate metric across an entire project,
  and a line-level detail. Presenting all this information elegantly can be a
  challenge.

- The use of color to express information can be very effective.

- Little things like modal pop-out boxes for viewing specific files, syntax
  highlighting, sortable and searchable tables, etc. make for a dynamic and 
  pleasant experience

- A coverage tool could be implemented to work in a similar fashion to the
  command line utility `diff`, but that would make it much more cumbersome
  to work with.

- Coverage is a pretty boring context, so an attractive tool makes it feel a bit
  more pleasant to analyze coverage reports.


![](http://i.imgur.com/Bgskb.png)

### Good design makes a product understandable

> It clarifies the product’s structure. Better still, it can make the product
> clearly express its function by making use of the user's intuition. At best,
> it is self-explanatory.

Minitest stays with the Test Unit style, but does so in a much more simple way.
Internals are now understandle, too.

### Good design is unobtrusive

> Products fulfilling a purpose are like tools. They are neither decorative
> objects nor works of art. Their design should therefore be both neutral and
> restrained, to leave room for the user's self-expression.

Tilt

- Opinionated frameworks are overrated (when the opinion doesn't matter from the
  framework perspective)

- But frameworks shouldn't need to implement N adapters for every option they
  want to support.

### Good design is honest

> It does not make a product more innovative, powerful or valuable than it
> really is. It does not attempt to manipulate the consumer with promises that
> cannot be kept.

Rubyspec

- Exposes how well supported Ruby's functionality is across implementations
and versions.

- Makes it easy to see how much things change / break in the official Ruby
  distribution.

- Provides some insights into performance across implementations / versions.

- Gives implementators a level playing field to work with.

### Good design is long-lasting

> It avoids being fashionable and therefore never appears antiquated. Unlike
> fashionable design, it lasts many years – even in today's throwaway society.

Rubygems

### Good design is thorough down to the last detail

> Nothing must be arbitrary or left to chance. Care and accuracy in the design
> process show respect towards the consumer.

CSV

### Good design is environmentally friendly

> Design makes an important contribution to the preservation of the environment.
> It conserves resources and minimizes physical and visual pollution throughout
> the lifecycle of the product.

Spin

Spork:
  - Needs to be added to your tests
  - Needs to be added as a Gemfile dependency
  - Patches Rails


### Good design is as little design as possible

> Less, but better – because it concentrates on the essential aspects, and the
> products are not burdened with non-essentials. Back to purity, back to
> simplicity.

Rack

### Reflections

Every project we looked at in this article exhibits some, but not all of these
good design qualities, in varying degrees of intensity. Design is a balancing
act, and sometimes tensions exist between things in mutually exclusive ways.
Still, trying to do as best as possible on all of these metrics and only
making compromises when it is necessary to do so seems like a pretty good idea.


[principles]: http://en.wikipedia.org/wiki/Dieter_Rams#Rams.27_ten_principles_of_.22good_design.22
[ladder]: http://worrydream.com/LadderOfAbstraction/
[simplecov]: https://github.com/colszowka/simplecov
