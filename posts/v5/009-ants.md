*This article is based on a [heavily modified Ruby port][rubyantsim] 
of Rich Hickey's [Clojure ant simulator][hickey]. Although I didn't directly collaborate with Rich on this issue of 
Practicing Ruby, I learned a lot from his code and it provided
me with a great foundation to start from.*

Watch as a small ant colony identifies and completely consumes its four nearest
food sources:

<div align="center">
<iframe width="720" height="480"
src="http://www.youtube.com/embed/f2IX1Y5o6pc?rel=0" frameborder="0" allowfullscreen></iframe>
</div>

While this search effort may seem highly organized, it is the
result of very simple decisions made by individual ants. On each
tick of the simulation, each ant decides its next action based only on its
current location and the three adjacent locations ahead of it. But 
because ants can indirectly communicate via their environment, complex 
behavior arises in the aggregate.

Emergence and self-organization are popular concepts in programming, but far too many
developers start and end their explorations into these ideas with [Conway's Game of Life][conway]. 
In this article, I will help you see these fascinating properties in a new
light by demonstrating the role they play in [ant colony optimization (ACO)][aco] algorithms.

> **NOTE:** There are many ways to simulate ant behavior, some of which can be quite useful
for a wide range of search applications. For this article, I have built
a fairly naïve simulation that is meant to loosely mimic the kind of ant
behavior you can observe in the natural world. This article *may* be useful as a 
brief introduction to ACO, but be sure to dig deeper if you are interested in
practical applications. My goal is to provide a great example of emergent 
behavior, NOT a great reference for nature-inspired search algorithms.

## Building a minimal ant farm 

This simulated world consists of many cells: some are food sources, 
some are part of the colony's nest, and the rest are an
open field that needs to be traversed. Each cell can contain a single 
ant facing in one of the eight directions you'd find on a compass. 
As the ants move around the world, they mark the cells they visit with
a trail of pheremones that helps them find their way between their 
nest and nearby food sources. These pheremones accumulate as more and
more ants travel across a given trail, but they also gradually 
evaporate over time.

Simple value objects are used to define the 
properties of the `Ant`, `Cell`, and `World` structures that 
are needed to bring the simulation to life:

```ruby
module AntSim
  class Ant
    def initialize(direction, location)
      self.direction = direction
      self.location  = location
    end

    attr_accessor :food, :direction, :location
  end

  class Cell
    def initialize(food, home_pheremone, food_pheremone)
      self.food           = food 
      self.home_pheremone = home_pheremone
      self.food_pheremone = food_pheremone
    end

    attr_accessor :food, :home_pheremone, :food_pheremone, :ant, :home
  end

  class World
    def initialize(world_size)
      self.size = world_size
      self.data = size.times.map { size.times.map { Cell.new(0,0,0) } }
    end

    def [](location)
      x,y = location

      data[x][y]
    end

    def sample
      data[rand(size)][rand(size)]
    end

    def each
      data.each_with_index do |col,x| 
        col.each_with_index do |cell, y| 
          yield [cell, [x, y]]
        end
      end
    end

    private

    attr_accessor :data, :size
  end
end
```

These objects are somewhat peculiar in that they are very state-centric and 
do not encapsulate any interesting domain logic. Although it is not a very 
object-oriented solution, designing things this way makes it possible to 
decouple the state of the simulated world from both the events that happen 
within it and the optimization algorithms that run against it.


## Moving around from place to place

Possible movements for ants:

![Ant movement rules](http://i.imgur.com/VsBkn.png)

While it might not be obvious from the video, the world our ants live in is 
a [torus][torus], not a plane. This means that the leftmost column and the rightmost column
of the map are adjacent to one another, as are the top and bottom rows. Because
a donut-shaped surface does not have any corners to get stuck in, this helps
simplify a few calculations and eliminates a few edge cases for us. This is
non-standard topology is worth pointing out up front to avoid some confusion
later, but it isn't a critical detail to get hung up over. The shape of the
world our ants live in is much less important than the objects contained within
in it.


## Searching for delicious morsels

Exactly one of the following three things happens (in priority order): 

1. If the current cell is a food source, take some food, turn to face opposite
direction of current heading (i.e. if facing N, face S). Switch to delivery
behavior.

2. If the cell directly ahead is a food source and there is no ant blocking the
way, move to that cell, adding pheremone to the current cell.

3. Play roulette! (explain)

## Making it back to home base

Exactly one of the following three things happens (in priority order): 

1. If the current cell is home, drop the food, turn to face the opposite
  direction of current heading (i.e. if facing N, face S). Switch to foraging
  behavior.

2. If the cell directly ahead is home and there is no ant blocking the way, move to that 
cell, adding pheremone to the current cell.

3. Play roulette! (explain)

## Trending towards optimization 

* Pheremones decay gradually
* Shorter paths get repeated faster, increasing their pheremone
* Updating paths only on completion of one-way trip decreases random fluctuation
* Using two pheremones provides a sense of direction
* Every ant's individual contributions add up

## Reflections


[conway]: http://en.wikipedia.org/wiki/Conway%27s_Game_of_Life
[aco]: http://en.wikipedia.org/wiki/Ant_colony_optimization
[torus]: http://en.wikipedia.org/wiki/Torus
[hickey]: https://gist.github.com/1093917
[rubyantsim]: https://github.com/elm-city-craftworks/practicing-ruby-examples/tree/master/v5/009
