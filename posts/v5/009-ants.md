
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

## An oddly shaped ant farm 

* It is a torus
* It has pheremones for food and for home
* It has ants
* It has a home base for the ants
* It has many food sources

## Moving around from place to place

Possible movements for ants:

![Ant movement rules](http://i.imgur.com/VsBkn.png)

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
