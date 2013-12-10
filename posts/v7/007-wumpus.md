Link (or at least reference) each branch and provide a README for each.
[Audit and improve README information where needed]

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

## Discuss user interface (Narrator / Console)

## Building the game

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

[room-class]: https://github.com/elm-city-craftworks/wumpus/blob/master/lib/wumpus/room.rb


http://www.atariarchives.org/bcc1/showpage.php?page=247

http://en.wikipedia.org/wiki/Hunt_the_Wumpus

http://scv.bu.edu/miscellaneous/Games/wumpus.html

Dodecahedron generation:
http://stackoverflow.com/questions/1280586/hunt-the-wumpus-room-connection/1280611#1280611

Good visualization:
http://flockhart.virtualave.net/ajax/wumpus.html

