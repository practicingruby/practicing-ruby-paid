## Modeling the Room class

(diagram)

Every room has an identifying number, to help the player keep 
track of where they have been:

```ruby
let(:room) { Wumpus::Room.new(42) }

it "has a number" do
  room.number.must_equal(42)
end
```

Each room is connected to other rooms in the cave, and it is possible to 
look up and select neighboring rooms by their number, or via 
random selection:

```ruby
it "has connections to neighbors" do
  neighbors = [2,4,8].each do |i| 
    # create a connection to a neighboring room
    room.connect(Wumpus::Room.new(i)) 

    # a neighbor can be looked up by room number
    room.neighbor(i).number.must_equal(i)

    # Room connections are bidirectional
    room.neighbor(i).neighbor(room.number).must_equal(room)
  end

  # Can get numbers of all neighboring rooms
  room.exits.must_equal([2,4,8])

  # Can grab a random room
  [2,4,8].must_include(room.random_neighbor.number)
end
```

Rooms may contain hazards, which can be added or removed as the 
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

A room is considered safe only if there are no hazards within it
or any of its neighbors:

```ruby
  it "is not safe if it has hazards" do
    room.add(:wumpus)

    refute room.safe?
  end

  it "is not safe if its neighbors have hazards" do
    [2,4,8].each { |i| room.connect(Wumpus::Room.new(i)) }

    room.random_neighbor.add(:wumpus)

    refute room.safe?
  end

  it "is safe when it and its neighbors have no hazards" do
    [2,4,8].each { |i| room.connect(Wumpus::Room.new(i)) }

    assert room.safe?
  end
end
```

Because this class only handles basic data tranformations, it is very
straightforward to implement. Run `git pull origin room-tests` now to try 
implementing it yourself, or [view my solution][room-class]
before moving on.

## Modeling the Cave class

(diagram)

```ruby
let(:cave)  { Wumpus::Cave.dodecahedron }
let(:rooms) { (1..20).map { |i| cave.room(i) } }

it "has rooms that connect to exactly three other rooms" do
  rooms.each do |room|
    room.neighbors.count.must_equal(3)
    
    assert room.neighbors.all? { |e| e.neighbors.include?(room) }
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

  entrance.must_be_instance_of(Wumpus::Room)

  assert entrance.safe?
end
```

## Modeling the Player class


```ruby
let(:player) { Wumpus::Player.new }

let(:empty_room) { Wumpus::Room.new(1) }

let(:wumpus_room) do
  Wumpus::Room.new(2).tap { |e| e.add(:wumpus) }
end

let(:bat_room) do
  Wumpus::Room.new(3).tap { |e| e.add(:bats) }
end
```

```ruby
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
```

```ruby
it "can sense nearby hazards" do
  player.enter(empty_room)
  player.explore_room

  sensed.must_equal(Set["You hear a rustling", "You smell something terrible"])
  
  assert encountered.empty?
end
```

```ruby
it "can encounter hazards when entering a room" do
  player.enter(wumpus_room)

  encountered.must_equal(Set["The wumpus ate you up!"])

  encountered.clear

  player.enter(bat_room)

  encountered.must_equal(Set["The bats whisk you away!"])
  
  assert sensed.empty?
end
```

```ruby
it "can perform actions" do
  player.enter(empty_room)

  player.room.must_equal(empty_room)

  player.act(:move, wumpus_room)
  player.room.must_equal(wumpus_room)

  encountered.must_equal(Set["The wumpus ate you up!"])

  assert sensed.empty?
end
```

## Modeling the Narrator class

```ruby
it "can ask for input" do
  narrator = Wumpus::Narrator.new

  with_stdin do |user|
    user.puts("m")

    narrator.ask("What do you want to do? (m)ove or (s)hoot?").must_equal("m")
  end
end

it "can say things" do
  narrator = Wumpus::Narrator.new

  -> { narrator.say("Well hello there, stranger!") }
     .must_output("Well hello there, stranger!\n")
end

it "knows when the story is over" do
  narrator = Wumpus::Narrator.new

  refute narrator.finished?

  narrator.finish_story("It's done!")
  
  assert narrator.finished?

  -> { narrator.describe_ending }.must_output("It's done!\n")
end

it "knows how to tell a story from beginning to end" do
  narrator = Wumpus::Narrator.new

  chapters = (1..5).to_a

  out, err = capture_io do
    narrator.tell_story do
      narrator.say("Thus begins chapter #{chapters.shift}")

      if chapters.empty?
        narrator.finish_story("And they all lived happily ever after!")
      end
    end
  end

  expect_string_sequence(out, 
    /chapter 1/, /chapter 2/, /chapter 3/, /chapter 4/, /chapter 5/,
    /And they all lived happily ever after!/)
end
```

```ruby
# http://stackoverflow.com/a/16950202
def with_stdin
  stdin = $stdin             
  $stdin, write = IO.pipe    
  capture_io { yield(write) }               
ensure
  write.close                
  $stdin = stdin             
end

def expect_string_sequence(out, *patterns)
  scanner = StringScanner.new(out)

  patterns.each do |pattern|
    scanner.scan_until(pattern) or 
      flunk("Didn't find pattern #{pattern.inspect} in sequence")
  end

  pass
end
```

** LINK TO CONSOLE OBJECT **

## Building the game


```ruby
#!/usr/bin/env ruby
require_relative "../lib/wumpus"

# For testing, but also for restoring a world with the same conditions
srand(ARGV[0].to_i) if ARGV[0]

# World setup

cave = Wumpus::Cave.new

cave.add_hazard(:wumpus, 1)
cave.add_hazard(:pit, 3)
cave.add_hazard(:bats, 3)

# Player and narrator setup

player    = Wumpus::Player.new
narrator  = Wumpus::Narrator.new

console = Wumpus::Console.new(player, narrator)

# Senses

player.sense(:bats) do
  narrator.say("You hear a rustling sound nearby") 
end

player.sense(:wumpus) do
  narrator.say("You smell something terrible nearby")
end

player.sense(:pit) do
  narrator.say("You feel a cold wind blowing from a nearby cavern.")
end

# Encounters

player.encounter(:wumpus) do
  player.act(:startle_wumpus, player.room)
end

player.encounter(:bats) do
  narrator.say "Giant bats whisk you away to a new cavern!"

  old_room = player.room
  new_room = cave.random_room

  player.enter(new_room)

  cave.move(:bats, from: old_room, to: new_room)
end

player.encounter(:pit) do
  narrator.finish_story("You fell into a bottomless pit. Enjoy the ride!")
end

# Actions

player.action(:move) do |destination|
  player.enter(destination)
end

player.action(:shoot) do |destination|
  if destination.has?(:wumpus)
    narrator.finish_story("YOU KILLED THE WUMPUS! GOOD JOB, BUDDY!!!") 
  else
    narrator.say("Your arrow missed!")

    player.act(:startle_wumpus, cave.room_with(:wumpus))
  end
end

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

# Kick off the event loop

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
