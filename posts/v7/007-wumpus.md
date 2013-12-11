Hunt the Wumpus is a hide-and-seek game that takes place in an underground
cave network full of interconnected rooms. To win the game, the player
needs to locate the evil Wumpus and kill it while avoiding various different 
hazards that are hidden within in the cave.

Originally written by Gregory Yob in the 1970s, this game is traditionally
played using a text-based interface, which leaves plenty up to the
player's imagination, and also makes programming easier for those who
want to build Wumpus-like games of their own.

Because of its simple but clever nature, Hunt the Wumpus has been ported 
to many different platforms and programming languages over the last several
decades. In this article, you will discover why this blast from the past 
serves as an excellent example of creative computing, and you'll also 
learn how to implement it from scratch in Ruby.

## Gameplay demonstration

There are only two actions available to the player throughout the game: to move
from room to room, or to shoot arrows into nearby rooms in an attempt to kill 
the Wumpus. Until the player knows for sure where the Wumpus is, most of their actions 
will be dedicated to moving around the cave to gain a sense of its layout:

    You are in room 1.
    Exits go to: 2, 8, 5
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 2
    -----------------------------------------
    You are in room 2.
    Exits go to: 1, 10, 3
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 10
    -----------------------------------------
    You are in room 10.
    Exits go to: 2, 11, 9

Even after only a couple actions, the player can start to piece together
a map of the cave's topography, which will help them avoid getting lost
as they continue their explorations:

![](http://i.imgur.com/5gCTOAt.png)

Play continues in this fashion, with the player wandering around until 
a hazard is detected:

    What do you want to do? (m)ove or (s)hoot? m
    Where? 11
    -----------------------------------------
    You are in room 11.
    Exits go to: 10, 8, 20
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 20
    -----------------------------------------
    You are in room 20.
    You feel a cold wind blowing from a nearby cavern.
    Exits go to: 11, 19, 17

In this case, the player has managed to get close
to a bottomless pit, which is detected by the presence of
a cold wind emanating from an adjacent room.

Because hazards are sensed indirectly, the player needs to use a deduction
process to know for sure which hazards are in what rooms. With the knowledge of
the cave layout so far, the only thing that is for certain is there is at least one
pit nearby, with both rooms 17 and 19 being possible candidates. One of them
might be safe, but there is also a chance that BOTH rooms contain pits.
In a literal sense, the player might have reached a dead end:

![](http://i.imgur.com/D6aA2wl.png)

A risky player might chance it and try one of the two rooms, but
that isn't a smart way to play. The safe option is to 
backtrack in search of a different path through the cave:

    What do you want to do? (m)ove or (s)hoot? m
    Where? 11
    -----------------------------------------
    You are in room 11.
    Exits go to: 10, 8, 20
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 8
    -----------------------------------------
    You are in room 8.
    You smell something terrible nearby
    Exits go to: 11, 1, 7

Changing directions ends up paying off. Upon entering room 8,
the terrible smell that is sensed indicates the Wumpus is nearby,
and because rooms 1 and 11 have already been visited, there
is only one place left for the Wumpus to be hiding:

    What do you want to do? (m)ove or (s)hoot? s
    Where? 7
    -----------------------------------------
    YOU KILLED THE WUMPUS! GOOD JOB, BUDDY!!!

At the end of the hunt, the player's map ended up looking like this:

![](http://i.imgur.com/IZnqNNw.png)

In less fortunate circumstances, the player would need to do a lot more
exploration before they could be certain about where the Wumpus 
was hiding. Other hazards might also be encountered, including giant bats 
that are capable of moving the player to a random location in the cave.
Because all these factors are randomized in each new game, Hunt the Wumpus
can be played again and again without ever encountering an identical
cave layout.

We will discuss more about the game rules throughout the rest of this
article, but the few concepts illustrated in this demonstration are more 
than enough for us to start modeling some of the key game objects.
Let's get to work!

## Implementing "Hunt the Wumpus" from scratch

Like many programs from its era, Hunt the Wumpus was designed to 
be hackable. If you look at one of the [original publications][atari]
about the game, you can see that the author actively encourages
tweaking its rules, and even includes the full source code 
of the game.

Before you rush off to study the original implementation, remember that 
it was written four decades ago in BASIC. Unless you consider yourself
a technological archaeologist, it's probably not the best way to
learn about the game. With that in mind, I've put together a learning
exercise that will guide you through implementing some of the core 
game concepts of Hunt the Wumpus -- without getting bogged down in
specific game rules or having to write boring user interface code.

In particular, I want you to implement three classes that I have 
already written the tests for:

1. A `Wumpus::Room` class to manage hazards and connections between rooms
2. A `Wumpus::Cave` class to manage the overall topography of the cave
3. A `Wumpus::Player` class that handles sensing and encountering hazards

Once these three classes are written, you'll be able to use my UI code 
and game logic to play a rousing round of Hunt the Wumpus. You'll
also be able to compare your own work to my [reference implementation][FIXME]
of the game, and discuss any questions or thoughts with me about
the differences between our approaches.


## Modeling the Room class

The concept of a room is fundamental to the "Hunt the Wumpus" game,
so we can start by implementing them. Our goal will be to define
and then pass the following tests:

```ruby
describe "A room" do
  it "has a number"
  it "may contain hazards"

  describe "with neighbors" do
    it "has two-way connections to neighbors"
    it "knows the numbers of all neighboring rooms"
    it "can choose a neighbor randomly"
    it "is not safe if it has hazards" 
    it "is not safe if its neighbors have hazards"
    it "is safe when it and its neighbors have no hazards"
  end
end
```

Let's walk through each of these requirements individually and fill
in the necessary details.

**Design notes + unit tests**

Structurally speaking, rooms and their connections form a simple undirected graph:

![](http://i.imgur.com/p81T0Gn.png)

The bulk of the responsibility of the `Room` class will be to manage these
connections, and make it easy to query and manipulate the "hazards" that
can be found in a room, including bats, pits, and the wumpus itself.

1) Every room needs an identifying number, to help the player keep 
track of where they are:

```ruby
describe "A room" do
  let(:room) { Wumpus::Room.new(12) }

  it "has a number" do
    room.number.must_equal(12)
  end

  # ...
end
```

2) Rooms may contain hazards, which can be added or removed as the 
game progresses:

```ruby
it "may contain hazards" do 
  # rooms start out empty
  assert room.empty?

  # hazards can be added
  room.add(:wumpus)
  room.add(:bats)

  # a room with hazards isn't empty
  refute room.empty?

  # hazards can be detected by name
  assert room.has?(:wumpus)
  assert room.has?(:bats)

  refute room.has?(:alf)

  # hazards can be removed
  room.remove(:bats)
  refute room.has?(:bats)
end
```

3) Each room can be connected to other rooms in the cave:

```ruby
describe "with neighbors" do
  let(:exit_numbers) { [11, 3, 7] }

  before do
    exit_numbers.each { |i| room.connect(Wumpus::Room.new(i)) }
  end

   # ...
end
```

4) Connections between rooms are bidirectional; one-way
paths are not allowed.

```ruby
it "has two-way connections to neighbors" do
  exit_numbers.each do |i| 
    # a neighbor can be looked up by room number
    room.neighbor(i).number.must_equal(i)

    # Room connections are bidirectional
    room.neighbor(i).neighbor(room.number).must_equal(room)
  end
end
```

5) Each room knows all of its "exits", which are the identifying numbers 
for its neighbors:

```ruby
it "knows the numbers of all neighboring rooms" do
  room.exits.must_equal(exit_numbers)
end
```

6) Neighboring rooms can be selected at random, which is
useful for certain game events:

```ruby
it "can choose a neighbor randomly" do
  exit_numbers.must_include(room.random_neighbor.number)
end
```

7) A room is considered safe only if there are no hazards within it
or any of its neighbors:

```ruby
it "is not safe if it has hazards" do
  room.add(:wumpus)

  refute room.safe?
end

it "is not safe if its neighbors have hazards" do
  room.random_neighbor.add(:wumpus)

  refute room.safe?
end

it "is safe when it and its neighbors have no hazards" do
  assert room.safe?
end
```

**Implementation notes**

Because this class only handles basic data tranformations, it is very
straightforward to implement. Run `git pull origin room-tests` now to try 
implementing it yourself, or [view my solution][room-class]
before moving on.

## Modeling the Cave class


```ruby
describe "A cave" do
  it "has 20 rooms that each connect to exactly three other rooms" 
  it "can select rooms at random"
  it "can move hazards from one room to another"
  it "can add hazards at random to a specfic number rooms"
  it "can find a room with a particular hazard"
  it "can find a safe room to serve as an entrance"
end
```

**Design notes + unit tests**

![](http://i.imgur.com/Myxk4vS.png)

```ruby
describe "A cave" do
  let(:cave)  { Wumpus::Cave.dodecahedron }
  let(:rooms) { (1..20).map { |i| cave.room(i) } }

  it "has 20 rooms that each connect to exactly three other rooms" do
    rooms.each do |room|
      room.neighbors.count.must_equal(3)
      
      assert room.neighbors.all? { |e| e.neighbors.include?(room) }
    end
  end
end
```

```ruby
it "can select rooms at random" do
  sampling = Set.new

  must_eventually("randomly select each room") do
    new_room = cave.random_room 
    sampling << new_room

    sampling == Set[*rooms] 
  end
end
```

```ruby
# consider linking rather than including source here.

def must_eventually(message, n=1000)
  n.times { yield and return pass }
  flunk("Expected to #{message}, but didn't")
end
```

```ruby
it "can move hazards from one room to another" do
  room      = cave.random_room
  neighbor  = room.neighbors.first

  room.add(:bats)

  assert room.has?(:bats)
  refute neighbor.has?(:bats)

  cave.move(:bats, :from => room, :to => neighbor)

  refute room.has?(:bats)
  assert neighbor.has?(:bats)
end
```

```ruby
it "can add hazards at random to a specfic number rooms" do
  cave.add_hazard(:bats, 3)

  rooms.select { |e| e.has?(:bats) }.count.must_equal(3)
end
```

```ruby
it "can find a room with a particular hazard" do
  cave.add_hazard(:wumpus, 1)

  assert cave.room_with(:wumpus).has?(:wumpus)
end
```

```ruby
it "can find a safe room to serve as an entrance" do
  cave.add_hazard(:wumpus, 1)
  cave.add_hazard(:pit, 3)
  cave.add_hazard(:bats, 3)

  entrance = cave.entrance

  assert entrance.safe?
end
```

**Implementation notes**

* A dodecahedron.json file is provided.
* Note subtleties of `add_hazard` ## Modeling the Player class

## Modeling the Player class

```ruby
describe "the player" do
  it "can sense hazards in neighboring rooms"
  it "can encounter hazards when entering a room"
  it "can perform actions"
end
```

**Design notes + unit tests**

![](http://i.imgur.com/tlCrFkn.png)

```ruby
describe "the player" do
  let(:player) { Wumpus::Player.new }

  let(:empty_room) { Wumpus::Room.new(1) }

  let(:wumpus_room) do
    Wumpus::Room.new(2).tap { |e| e.add(:wumpus) }
  end

  let(:bat_room) do
    Wumpus::Room.new(3).tap { |e| e.add(:bats) }
  end

  let(:sensed)      { Set.new }
  let(:encountered) { Set.new }

  before do
    empty_room.connect(bat_room)
    empty_room.connect(wumpus_room)

    player.sense(:bats) do
      sensed << "You hear a rustling"
    end

    player.sense(:wumpus) do
      sensed << "You smell something terrible"
    end

    player.encounter(:wumpus) do
      encountered << "The wumpus ate you up!"
    end

    player.encounter(:bats) do
      encountered << "The bats whisk you away!"
    end

    player.action(:move) do |destination|
      player.enter(destination)
    end
  end
end
```

```ruby
it "can sense hazards in neighboring rooms" do
  player.enter(empty_room)
  player.explore_room

  sensed.must_equal(Set["You hear a rustling", "You smell something terrible"])
  
  assert encountered.empty?
end
```

```ruby
it "can encounter hazards when entering a room" do
  player.enter(bat_room)
  encountered.must_equal(Set["The bats whisk you away!"])
  
  assert sensed.empty? 
end
```

```ruby
it "can perform actions" do
  player.act(:move, wumpus_room)
  player.room.must_equal(wumpus_room)

  encountered.must_equal(Set["The wumpus ate you up!"])
  assert sensed.empty?
end
```

## Defining the game rules

```ruby
cave = Wumpus::Cave.dodecahedron

cave.add_hazard(:wumpus, 1)
cave.add_hazard(:pit, 3)
cave.add_hazard(:bats, 3)
```


```ruby
player    = Wumpus::Player.new
narrator  = Wumpus::Narrator.new

player.sense(:bats) do
  narrator.say("You hear a rustling sound nearby") 
end

player.sense(:wumpus) do
  narrator.say("You smell something terrible nearby")
end

player.sense(:pit) do
  narrator.say("You feel a cold wind blowing from a nearby cavern.")
end
```

```ruby
player.encounter(:wumpus) do
  player.act(:startle_wumpus, player.room)
end
```

```ruby
player.encounter(:bats) do
  narrator.say "Giant bats whisk you away to a new cavern!"

  old_room = player.room
  new_room = cave.random_room

  player.enter(new_room)

  cave.move(:bats, from: old_room, to: new_room)
end
```

```ruby
player.encounter(:pit) do
  narrator.finish_story("You fell into a bottomless pit. Enjoy the ride!")
end
```

```ruby
player.action(:move) do |destination|
  player.enter(destination)
end
```

```ruby
player.action(:shoot) do |destination|
  if destination.has?(:wumpus)
    narrator.finish_story("YOU KILLED THE WUMPUS! GOOD JOB, BUDDY!!!") 
  else
    narrator.say("Your arrow missed!")

    player.act(:startle_wumpus, cave.room_with(:wumpus))
  end
end
```

```ruby
player.action(:startle_wumpus) do |old_wumpus_room|
  if [:move, :stay].sample == :move
    new_wumpus_room = old_wumpus_room.random_neighbor
    cave.move(:wumpus, from: old_wumpus_room, to: new_wumpus_room)

    narrator.say("You heard a rumbling in a nearby cavern.")
  end

  if player.room.has?(:wumpus)
    narrator.finish_story("You woke up the wumpus and he ate you!")
  end
end
```

```ruby
console = Wumpus::Console.new(player, narrator)

player.enter(cave.entrance)

narrator.tell_story do
  console.show_room_description
  console.ask_player_to_act
end
```

## Additional Exercises

[room-class]: https://github.com/elm-city-craftworks/wumpus/blob/master/lib/wumpus/room.rb
[atari]: http://www.atariarchives.org/bcc1/showpage.php?page=247


http://www.atariarchives.org/bcc1/showpage.php?page=247

http://en.wikipedia.org/wiki/Hunt_the_Wumpus

http://scv.bu.edu/miscellaneous/Games/wumpus.html

Dodecahedron generation:
http://stackoverflow.com/questions/1280586/hunt-the-wumpus-room-connection/1280611#1280611

Good visualization:
http://flockhart.virtualave.net/ajax/wumpus.html

