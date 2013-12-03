## Wumpus

(describe the game and its magic)

(hint at what can be learned)

## Project structure

* Room
* Cave
* Player
* Narrator
* bin/wumpus

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

```ruby
require "set"

require_relative "../helper"

describe "A cave" do
  let(:cave) { Wumpus::Cave.new }
  let(:rooms) { (1..20).map { |i| cave.room(i) } }
  
  it "is dodecahedron shaped" do
    rooms.each do |room|
      room.neighbors.count.must_equal(3)
      
      assert room.neighbors.all? { |e| e.neighbors.include?(room) }
    end
  end

  it "can select rooms at random" do
    sampling = Set.new

    must_eventually("randomly select each room") do
      new_room = cave.random_room 
      sampling << new_room

      sampling == Set[*rooms] 
    end
  end

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

  it "can add hazards at random to a specfic number rooms" do
    cave.add_hazard(:bats, 3)

    rooms.select { |e| e.has?(:bats) }.count.must_equal(3)
  end

  it "can find a room with a particular hazard" do
    cave.add_hazard(:wumpus, 1)

    assert cave.room_with(:wumpus).has?(:wumpus)
  end

  it "can find a safe room to serve as an entrance" do
    cave.add_hazard(:wumpus, 1)
    cave.add_hazard(:pit, 3)
    cave.add_hazard(:bats, 3)

    entrance = cave.entrance

    entrance.must_be_instance_of(Wumpus::Room)

    assert entrance.safe?
  end

  def must_eventually(message, n=1000)
    n.times { yield and return pass }
    flunk("Expected to #{message}, but didn't")
  end
end
```

[room-class]: https://github.com/elm-city-craftworks/wumpus/blob/master/lib/wumpus/room.rb

--------------------------------------------------

There is a cave. It is made up of 20 rooms laid out in a dodecahedron,
with three connections between each room.

```ruby
cave = Wumpus::Cave.new
```

The cave has a number of hazards, the main one being the wumpus itself. However,
there are also bottomless pits for the player to fall into, and bats that will
carry the player off to random rooms.

```ruby
cave.add_hazard(:wumpus, 1)
cave.add_hazard(:pit, 3)
cave.add_hazard(:bats, 3)
```

There are also models for the player itself (which starts at a random safe
location in the cave), and a narrator who "tells the player's story" by handling
input and output on the command line.

```ruby
player   = Wumpus::Player.new(cave.entrance)
narrator = Wumpus::Narrator.new(player)
```

The player is able to sense hazards in rooms adjacent to their current 
location. These senses do not tell us exactly *where* the hazard is, but do give
us a way to figure that out through deduction. Approaching a room from several
different angles will allow you to isolate what hazard is in what room.

```ruby
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

The player only has two direct actions available: to move into a neighboring
room, or to shoot into a neighboring room. Both of these actions may lead
to the indirect action of startling the wumpus.

When the wumpus is startled, it has a chance of either staying where it is, or
moving into an adjacent room.

If the wumpus ends up in the same place as the player after it has been
startled, it kills the player.

(fix this description, it's terrible and probably inaccurate ^)

```ruby
player.action(:move) do |destination|
  player.enter(destination)
end

player.action(:shoot) do |destination|
  wumpus_room = cave.room_with(:wumpus)

  if wumpus_room == destination
    narrator.finish_story("YOU KILLED THE WUMPUS! GOOD JOB, BUDDY!!!") 
  else
    narrator.say("Your arrow missed!")

    player.act(:startle_wumpus, wumpus_room)
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
```

Whenever a player enters a room, events can occur based on what hazards are in
that room. Moving into the wumpus's room startles it, moving into a room with
bats causes them to move the player to a random location, and moving into a room
with a pit causes the player to die.

```ruby
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
```

All of these events are triggered by the narrator "telling the story", which
alternates between accepting input from the player and printing out descriptions
of the rooms and events of the game.

```ruby
# Kick off the event loop
narrator.tell_story
```

An example transcript should go here.


---

All of this functionality is built on top of four classes, the `Cave`, the
`Room`, the `Player`, and the `Narrator`.

Let's start by looking at the `Room` class.

At its heart, a room consists of an identifying number (between 1 and 20), 
a set of connections to its neighbors, and a set of hazards. The
`Room` class models those attributes and provides some basic helper
methods for manipulating them:

```ruby
require "set"

module Wumpus
  class Room
    def initialize(number)
      @number    = number
      @neighbors = Set.new
      @contents  = []
    end

    attr_reader :number, :neighbors

    def add(thing)
      @contents.push(thing)
    end

    def remove(thing)
      @contents.delete(thing)
    end

    def has?(thing)
      @contents.include?(thing)
    end

    def empty?
      @contents.empty?
    end

    def safe?
      empty? && neighbors.all? { |e| e.empty? }
    end

    def connect(other_room)
      neighbors << other_room

      other_room.neighbors << self
    end

    def exits
      neighbors.map { |e| e.number }
    end

    def neighbor(number)
      neighbors.find { |e| e.number == number }
    end

    def random_neighbor
      neighbors.to_a.sample
    end
  end
end
```

Although it's technically possible to model an arbitrary cave layout using only
`Room` objects, it makes sense to create a `Cave` class to manage these objects
in aggregate.

A cave is nothing more than a collection of `Room` objects that model
a particular topological layout:

```ruby
module Wumpus
  class Cave
    def initialize
      @rooms = (1..20).map.with_object({}) { |i, h| h[i] = Room.new(i) }
      build_dodechadron_layout
    end

    def add_hazard(thing, count)
      count.times do
        room = random_room

        redo if room.has?(thing)

        room.add(thing) 
      end
    end

    def random_room
      @rooms.values.sample
    end

    def move(thing, from: raise, to: raise)
      from.remove(thing)
      to.add(thing)
    end

    def room_with(thing)
      @rooms.values.find { |e| e.has?(thing) }
    end

    def entrance
      @entrance ||= @rooms.values.find(&:safe?)
    end

    def room(number)
      @rooms[number]
    end

    def build_dodechadron_layout
      connections = [[1,2],[2,10],[10,11],[11,8],[8,1],
                     [1,5],[2,3],[9,10],[20,11],[7,8],
                     [5,4],[4,3],[3,12],[12,9],[9,19],
                     [19,20],[20,17],[17,7],[7,6],[6,5],
                     [4,14],[12,13],[18,19],[16,17],
                     [15,6],[14,13],[13,18],[18,16],
                     [16,15],[15,14]]

      connections.each { |a,b| @rooms[a].connect(@rooms[b]) }
    end
  end
end
```

For the most part, the job of the `Cave` is to serve as a collection of rooms,
and to manage interactions with those rooms.

It starts out by construction a topology that's equivalent to a dodecahedron:

```ruby
    def build_dodechadron_layout
      connections = [[1,2],[2,10],[10,11],[11,8],[8,1],
                     [1,5],[2,3],[9,10],[20,11],[7,8],
                     [5,4],[4,3],[3,12],[12,9],[9,19],
                     [19,20],[20,17],[17,7],[7,6],[6,5],
                     [4,14],[12,13],[18,19],[16,17],
                     [15,6],[14,13],[13,18],[18,16],
                     [16,15],[15,14]]

      connections.each { |a,b| @rooms[a].connect(@rooms[b]) }
    end
```

With these connections made, it's possible to add hazards to
rooms, taking care of a few corner cases in the process.



```ruby
module Wumpus
  class Player
    def initialize(room)
      @senses     = {}
      @encounters = {}
      @actions    = {}
      @room       = room
    end

    attr_reader :room

    def sense(thing, &callback)
      @senses[thing] = callback
    end

    def encounter(thing, &callback)
      @encounters[thing] = callback
    end

    def action(thing, &callback)
      @actions[thing] = callback
    end

    def enter(room)
      @room = room

      @encounters.each do |thing, action|
        return(action.call) if room.has?(thing)
      end
    end

    def explore_room
      @senses.each do |thing, action|
        action.call if @room.neighbors.any? { |e| e.has?(thing) }
      end
    end

    def act(action, destination)
      @actions[action].call(destination)
    end
  end
end
```

```ruby
module Wumpus
  class Narrator
    def initialize(player)
      @player = player
    end

    def say(message)
      STDOUT.puts message
    end

    def ask(question)
      print "#{question} "
      STDIN.gets.chomp
    end

    def tell_story
      until finished?
        describe_room
        ask_player_to_act
      end

      describe_ending
    end

    def finish_story(message)
      @ending_message = message
    end

    private
    
    def finished?
      !!@ending_message
    end

    def describe_ending
      say "-----------------------------------------"
      say @ending_message
    end

    def describe_room
      say "-----------------------------------------"
      say "You are in room #{@player.room.number}."

      @player.explore_room

      say "Exits go to: #{@player.room.exits.join(', ')}"
    end

    def ask_player_to_act
      actions = {"m" => :move, "s" => :shoot, "i" => :inspect }
      
      accepting_player_input do |command, room_number| 
        @player.act(actions[command], @player.room.neighbor(room_number))
      end
    end

    def accepting_player_input
      say "-----------------------------------------"
      command = ask("What do you want to do? (m)ove or (s)hoot?")

      unless ["m","s"].include?(command)
        say "INVALID ACTION! TRY AGAIN!"
        return
      end

      dest = ask("Where?").to_i

      unless @player.room.exits.include?(dest)
        say "THERE IS NO PATH TO THAT ROOM! TRY AGAIN!"
        return
      end

      yield(command, dest)
    end
  end
end
```














































----------------------------------------------------------------------

> This issue of Practicing Ruby is a short story in prose and code. It
draws its inspiration directly from a [text-based game](http://en.wikipedia.org/wiki/Hunt_the_Wumpus) 
from Gregory Yob that was released in the 1970s, and is meant to
reconnect you with the lighter side of programming.

Ruth set herself down on her grandfather's living room floor, surrendering to
the rising tide of boredom that had been tugging at her since the moment she
first arrived at his apartment. In the kitchen, Grandpa Joe sipped coffee and
stared off into nowhere. He was trying to remember the last time he and Ruth 
had done something fun together, but he felt like he was just grasping at 
straws. He had become a dull old man, and he knew it.

Not able to stand the silence any longer, Ruth yelled down the hallway to her
daydreaming elder. "Were you always this boring? Or is it the result of a
hundred years of practice?", she asked in a way that blended sarcasm with
sincerity. He didn't say anything in response, but her cajoling did
prompt him to join her in the living room, where he sat down on the sofa and
then quickly got back to staring at nothing at all while his mind continued 
to ruminate. The sad look on his face was enough to make Ruth feel guilty for
teasing him. "It was just a joke Grandpa, please don't take it so seriously",
she said with a bit of regret.

He looked at her with tired eyes, then asked her a question that seemed
a bit odd: "Do you know that I used to write software for a living?"

"What's that got to do with anything?", Ruth asked as she moved across
the room to sit down next to her grandfather. For the first time in what 
felt like years, she felt genuinely interested in what the old man had to say.

"Yes, back when I was your mother's age, many people wrote software. We wrote the
code for nearly everything: from the kind of stuff that keeps planes in the sky,
to the software that managed people's banks accounts. I was never involved in
work that was quite so serious, but I still did a few interesting jobs in my day."

All of this sounded like pure fantasy to Ruth, who had always assumed that 
software was something that machines took care of building
themselves. The thought that any human could be trusted to directly control 
a computer was shocking on its own, but imagining her musty old Grandpa Joe doing
that sort of work made her giggle in disbelief. "You? A programmer? That's
funny, Grandpa Joe."

"It's the truth, Ruth. Long before there were AI systems to do programming work
for us, people did it. And some of us were even good at it. Some people enjoyed
programming so much, they even did it for fun." 

Grandpa Joe was getting impatient now, momentarily forgetting that this part 
of history was conveniently left out of modern primary school education. The 
machine-controlled world had little to gain in inspiring people to 
try to take back some of the power that humans once had over computers,
so the topic was simply never taught to the younger generations. It wasn't
exactly prohibited to learn about programming, but the machines did their best 
to make sure people would never feel the need to do so.

"You must have grown up in terrible times, Grandpa Joe. The idea that
programming a machine could be 'fun' sounds silly to me. Depending on the task,
it must have been either painfully boring or dreadfully dangerous."

Ruth frowned, slightly unsure about the words that had just come out of her
mouth. How in the world could working with machines be fun? They usually just
frustrated her with their cold indifference and utter incomprehensibility.
Machines took care of the work that humans were too slow or stupid to do, but
they weren't exactly known for their personality.

Without warning, the old man leaped into the air as if he had been struck 
by lightning. He could hardly contain his excitement as he sprung to life
with a sudden urgency. "I've got it Ruth! I know what we can do today!"

The old man ran to a closet and pulled out an old dusty card that vaguely resembled
the lesson cards used by rapid learning machines. It was obviously homemade,
but he held it with such pride and care that Ruth couldn't be help but wonder
what its contents were.

"I made this years ago, but I nearly forgot about it. Please take it down
to the library and use the learning machine to study its lessons. It should be
able to teach you everything you need to know about computers and programming
to do something fun with me today."

Ruth had used rapid learning machines plenty of times before, but all of the
lessons she had studied had been machine-made. The thought of using a man-made
lesson card made her a little nervous, but she knew that there were enough safety
controls that the worst thing that could happen is that she'd waste a few hours
at the library and not end up learning anything at all. Because Ruth didn't want
to sink back into that painful boredom she had felt just minutes earlier, she
decided to take a chance and headed down to the library. Grandpa Joe's
lesson actually worked!

A few hours later, Ruth returned to her grandfather's apartment and saw that he had set
up an ancient looking computer on his kitchen table, which he was already
rapidly typing commands into. Now that she had the necessary background
knowledge to be convinced that humans actually could program computers, she 
felt a bit less incredulous and simply asked him what it was they were going 
to do together.

He looked at her for a moment with a quiet intensity, and then
responded: "Isn't it obvious, child? We're going to hunt the wumpus!"

## The journey begins...

"What in the world is a Wumpus?", Ruth asked.

"It's a terrible cave-dwelling beast", said Grandpa Joe, 
"and by golly, we're going to hunt it!"

Ruth looked at the old man and sighed deeply. It would seem that
she had got her hopes up for nothing, and that today would
be the usual mix of boring and crazy she had come to expect
from her grandfather.

"Grandpa, I thought you said we were going to write computer programs,
and now you're talking nonsense about a hunting trip. Did you 
forget to take your medication today?"

The old man was frustrated by her accusation, but it wasn't enough to curb his
enthusiasm.

"Don't be so annoyed, my dear. We're going to do both! Today we're
going build a *computer game* together. All we need to do is
write a little bit of code and use our imaginations, and we'll
be hunting the Wumpus in no time at all."

The puzzled look on Ruth's face made it clear to the old man just where the
disconnect was. His granddaughter didn't know the first thing about "video
games", and to be frank, she didn't have much of a sense of "imagination",
either. The world she lived in leaned heavily on virtual reality 
for entertainment. Those big-budget affairs had plenty of room for 
personalization, but they were intentionally designed to leave very little 
up to the imagination. To Ruth, the concept of cooking up a little game in your living 
room using nothing but the ideas in your head was a completely foreign concept. 

"I'm sorry Grandpa, maybe you aren't crazy, but I still don't get it."

The old man felt glad to hear her say this, because he could tell from her voice
that she was still interested, even if she didn't come out and say it.

"I know this is a bit uncomfortable for you Ruth, and I'm sorry for rushing
ahead with things. I'm 100 years older than you are, and we both know
that a lot has changed about the world in the last century. I think
that's why we're having such a hard time understanding each other.

Let me back up a little bit and fill in some details for you. The game
we're going to build today is based on one that was originally built
by Gregory Yob back in the 1970s, and it's called 'Hunt the Wumpus'.
He originally wrote that game using the BASIC programming language,
but even back in my day that was considered a rather ancient
and awkward language to work with. So I think today we'll work
with the Ruby language, which you should now understand at least
as well as I do -- assuming that lesson card did its job right.

Programming can be really complicated, and sometimes it's better
to just get started and figure things out as you go, and maybe if we did 
that, it would be a bit less overwhelming for you. What do you think?"

Ruth sat quietly for a moment, considering her grandfather's words. Realizing
that she had nothing to lose in trying to understand what the hell he was
talking about, she nodded in agreement, and their journey began.

## Wumpus in a linear cave, kills hunter on contact

```ruby
#
#    1 - 2 - 3 - 4 - 5 - 6 - 7 - 8 - 9 - 10
# 

require "set"

class Room
  def initialize(number)
    @number    = number
    @neighbors = Set.new
  end

  attr_reader :number, :neighbors

  def connect(other_room)
    neighbors << other_room

    other_room.neighbors << self
  end

  def neighboring_room_numbers 
    neighbors.map { |e| e.number }
  end

  def find_neighbor(number)
    neighbors.find { |e| e.number == number }
  end
end

class Narrator
  def initialize(current_room, wumpus_room)
    @current_room = current_room
    @wumpus_room  = wumpus_room
  end

  def describes_room
    puts "-----------------------------------------"
    puts "You are in room #{@current_room.number}."
    puts "Exits go to: #{exits.join(', ')}"
  end

  def asks_player_to_act
    puts "-----------------------------------------"
    print "Where do you want to go? "

    choice = gets.to_i

    if exits.include?(choice) 
      @current_room = @current_room.find_neighbor(choice)
    else
      puts "THERE IS NO PATH TO THAT ROOM! TRY AGAIN!"
    end
  end

  def finished?
    @current_room == @wumpus_room
  end

  def describe_ending
    puts "-----------------------------------------"
    puts "The wumpus gobbled you up. GAME OVER!"
  end

  private

  def exits
    @current_room.neighboring_room_numbers
  end
end

rooms = (1..10).map{ |i| Room.new(i) }
rooms.each_cons(2) { |a,b| a.connect(b) }

current_room = rooms.first
wumpus_room  = rooms[5..-1].sample

narrator = Narrator.new(current_room, wumpus_room)

until narrator.finished?
  narrator.describes_room
  narrator.asks_player_to_act
end

narrator.describe_ending
```

## Stench is added


```ruby
class Narrator
  # ...

  def describes_room
    puts "-----------------------------------------"
    puts "You are in room #{@current_room.number}."

    if exits.include?(@wumpus_room.number)
      puts "You smell something terrible."
    end

    puts "Exits go to: #{exits.join(', ')}"
  end
end
```

## Hunter gets arrows (limit one room range)

**FIXME: Clean up code (just enough to make change easier later)**

```ruby
class Narrator
  # ...

  def asks_player_to_act
    accepting_player_input do |action, dest|
      case action
      when "m"
        @current_room = @current_room.find_neighbor(dest)

        if @current_room == @wumpus_room
          game_over("The wumpus gobbled you up. GAME OVER!")
        end
      when "s"
        if @current_room.find_neighbor(dest) == @wumpus_room
         game_over("YOU KILLED THE WUMPUS! GOOD JOB, BUDDY!!!")
        else
          puts "Your arrow didn't hit anything. Try a different room?"
        end
      end
    end
  end

  private

  def game_over(message)
    @ending_message = message
  end

  def accepting_player_input
    puts "-----------------------------------------"
    print "What do you want to do? (m)ove or (s)hoot? "
    action = gets.chomp

    unless ["m","s"].include?(action)
      puts "INVALID ACTION! TRY AGAIN!"
      return
    end

    print "Where? "
    dest = gets.to_i

    unless exits.include?(dest)
      puts "THERE IS NO PATH TO THAT ROOM! TRY AGAIN!"
      return
    end

    yield(action, dest)
  end
end
```

## Topology is made from a line, into a small map, into dodecahedron

![](http://i.imgur.com/zxwQXnp.png)

```ruby
rooms = (1..10).map{ |i| Room.new(i) }
rooms.each_cons(2) { |a,b| a.connect(b) }

current_room = rooms.first
wumpus_room  = rooms[5..-1].sample
```

![](http://i.imgur.com/aBk2aB8.png)


```ruby
rooms = (1..10).map.with_object({}) { |i, h| h[i] = Room.new(i) }

connections = [[1,2],[1,3],[2,4],[2,5],[3,6],[3,7],[4,7],[4,8],
               [5,6],[5,8],[6,9],[7,9],[8,10],[9,10]]



connections.each { |a,b| rooms[a].connect(rooms[b]) }

current_room = rooms[1]
wumpus_room  = rooms[rand(5..10)]
```


    -----------------------------------------
    You are in room 1.
    Exits go to: 2, 3
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 2
    -----------------------------------------
    You are in room 2.
    Exits go to: 1, 4, 5
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 4
    -----------------------------------------
    You are in room 4.
    You smell something terrible.
    Exits go to: 2, 7, 8
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 2
    -----------------------------------------
    You are in room 2.
    Exits go to: 1, 4, 5
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 5
    -----------------------------------------
    You are in room 5.
    You smell something terrible.
    Exits go to: 2, 6, 8
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? s
    Where? 8
    -----------------------------------------
    YOU KILLED THE WUMPUS! GOOD JOB, BUDDY!!!

(revise mapping file to implement dodecahedron)

```ruby
rooms = (1..20).map.with_object({}) { |i, h| h[i] = Room.new(i) }

connections = [[1,2],[2,10],[10,11],[11,8],[8,1],
               [1,5],[2,3],[9,10],[20,11],[7,8],
               [5,4],[4,3],[3,12],[12,9],[9,19],
               [19,20],[20,17],[17,7],[7,6],[6,5],
               [4,14],[12,13],[18,19],[16,17],
               [15,6],[14,13],[13,18],[18,16],
               [16,15],[15,14]]

connections.each { |a,b| rooms[a].connect(rooms[b]) }

current_room = rooms[rand(1..20)]
wumpus_room  = rooms[rand(1..20)]
```


![](http://upload.wikimedia.org/wikipedia/commons/thumb/6/66/POV-Ray-Dodecahedron.svg/300px-POV-Ray-Dodecahedron.svg.png)
![](http://i.imgur.com/FwFdfZZ.png)


    -----------------------------------------
    You are in room 10.
    Exits go to: 2, 11, 9
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 2
    -----------------------------------------
    You are in room 2.
    Exits go to: 1, 10, 3
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 1
    -----------------------------------------
    You are in room 1.
    Exits go to: 2, 8, 5
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 8
    -----------------------------------------
    You are in room 8.
    Exits go to: 11, 1, 7
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 7
    -----------------------------------------
    You are in room 7.
    You smell something terrible.
    Exits go to: 8, 17, 6
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 8
    -----------------------------------------
    You are in room 8.
    Exits go to: 11, 1, 7
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 1
    -----------------------------------------
    You are in room 1.
    Exits go to: 2, 8, 5
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 5
    -----------------------------------------
    You are in room 5.
    Exits go to: 1, 4, 6
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 1
    -----------------------------------------
    You are in room 1.
    Exits go to: 2, 8, 5
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 8
    -----------------------------------------
    You are in room 8.
    Exits go to: 11, 1, 7
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? m
    Where? 7
    -----------------------------------------
    You are in room 7.
    You smell something terrible.
    Exits go to: 8, 17, 6
    -----------------------------------------
    What do you want to do? (m)ove or (s)hoot? s
    Where? 17
    -----------------------------------------
    YOU KILLED THE WUMPUS! GOOD JOB, BUDDY!!!


(screenshots are placeholders, see keynote file for raw assets)

## Pits added + Wind added

## Bats added (they move to wherever they drop you) + Rustling added

## Crooked arrows added (explicitly specify room numbers, if wrong path, random selection)

## Wumpus movement added (arrows and room entering)

## Morals

The joy of working on an interesting problem
The joy of leaving something up to the imagination
The joy of writing code with someone else
The beauty of growing a simple idea into something useful

---

Bonus (or homework for Ruth):

- Room number randomization
- Visual UI
- Asymettrical connection topology (ala BSDGames wump)

http://www.atariarchives.org/bcc1/showpage.php?page=247

http://en.wikipedia.org/wiki/Hunt_the_Wumpus

http://scv.bu.edu/miscellaneous/Games/wumpus.html

Dodecahedron generation:
http://stackoverflow.com/questions/1280586/hunt-the-wumpus-room-connection/1280611#1280611

Good visualization:
http://flockhart.virtualave.net/ajax/wumpus.html

Objects -
  Wumpus - a beast that eats anyone that enters its room.
  Agent - the player that traverses the world in search of gold and while trying to kill the wumpus.
  Bats (not available in all versions) - creatures that instantly carry the agent to a different room.
  Pits - bottomless pit that will trap anyone who enters the room except for the wumpus.

Actions - There are six possible actions:
  A simple move Forward.
  A simple Turn Left by 90°.
  A simple Turn Right by 90°.
  The action Grab can be used to pick up gold when in the same room as gold.
  The action Shoot can be used to fire an arrow in a straight line in the current direction the agent is facing. The arrow continues until it hits and kills the wumpus or hits a wall.
  The action Climb can be used to climb out of the cave but only when in the initial start position.

Senses - There are five senses, each only gives one bit of information:
  In the square containing the wumpus and in the directly (not diagonal) adjacent squares, the agent will perceive a Stench.
  In the squares directly adjacent to the bats, the agent will perceive the Bats
  In the squares directly adjacent to a pit, the agent will perceive a Breeze.
  In the square where gold is, the agent will perceive a Glitter.
  When the agent walks into a wall, the agent will perceive a Bump.

----

```
0010  REM- HUNT THE WUMPUS
0015  REM:  BY GREGORY YOB
0020  PRINT "INSTRUCTIONS (Y-N)";
0030  INPUT I$
0040  IF I$="N" THEN 52
0050  GOSUB 1000
0052  REM- ANNOUNCE WUMPUSII FOR ALL AFICIONADOS ... ADDED BY DAVE
0054  PRINT
0056  PRINT "     ATTENTION ALL WUMPUS LOVERS!!!"
0058  PRINT "     THERE ARE NOW TWO ADDITIONS TO THE WUMPUS FAMILY";
0060  PRINT " OF PROGRAMS."
0062  PRINT
0064  PRINT "     WUMP2:  SOME DIFFERENT CAVE ARRANGEMENTS"
0066  PRINT "     WUMP3:  DIFFERENT HAZARDS"
0067  PRINT
0068  REM- SET UP CAVE (DODECAHEDRAL NODE LIST)
0070  DIM S(20,3)
0080   FOR J=1 TO 20
0090    FOR K=1 TO 3
0100    READ S(J,K)
0110    NEXT K
0120   NEXT J
0130  DATA 2,5,8,1,3,10,2,4,12,3,5,14,1,4,6
0140  DATA 5,7,15,6,8,17,1,7,9,8,10,18,2,9,11
0150  DATA 10,12,19,3,11,13,12,14,20,4,13,15,6,14,16
0160  DATA 15,17,20,7,16,18,9,17,19,11,18,20,13,16,19
0170  DEF FNA(X)=INT(20*RND(0))+1
0180  DEF FNB(X)=INT(3*RND(0))+1
0190  DEF FNC(X)=INT(4*RND(0))+1
0200  REM-LOCATE L ARRAY ITEMS
0210  REM-1-YOU,2-WUMPUS,3&4-PITS,5&6-BATS
0220  DIM L(6)
0230  DIM M(6)
0240   FOR J=1 TO 6
0250   L(J)=FNA(0)
0260   M(J)=L(J)
0270   NEXT J
0280  REM-CHECK FOR CROSSOVERS (IE L(1)=L(2),ETC)
0290   FOR J=1 TO 6
0300    FOR K=J TO 6
0310    IF J=K THEN 330
0320    IF L(J)=L(K) THEN 240
0330    NEXT K
0340   NEXT J
0350  REM-SET# ARROWS
0360  A=5
0365  L=L(1)
0370  REM-RUN THE GAME
0375  PRINT "HUNT THE WUMPUS"
0380  REM-HAZARD WARNINGS & LOCATION
0390  GOSUB 2000
0400  REM-MOVE OR SHOOT
0410  GOSUB 2500
0420  GOTO O OF 440,480
0430  REM-SHOOT
0440  GOSUB 3000
0450  IF F=0 THEN 390
0460  GOTO 500
0470  REM-MOVE
0480  GOSUB 4000
0490  IF F=0 THEN 390
0500  IF F>0 THEN 550
0510  REM-LOSE
0520  PRINT "HA HA HA - YOU LOSE!"
0530  GOTO 560
0540  REM-WIN
0550  PRINT "HEE HEE HEE - THE WUMPUS'LL GETCHA NEXT TIME!!"
0560   FOR J=1 TO 6
0570   L(J)=M(J)
0580   NEXT J
0590  PRINT "SAME SET-UP (Y-N)";
0600  INPUT I$
0610  IF I$#"Y" THEN 240
0620  GOTO 360
1000  REM-INSTRUCTIONS
1010  PRINT "WELCOME TO 'HUNT THE WUMPUS'"
1020  PRINT "  THE WUMPUS LIVES IN A CAVE OF 20 ROOMS. EACH ROOM"
1030  PRINT "HAS 3 TUNNELS LEADING TO OTHER ROOMS. (LOOK AT A"
1040  PRINT "DODECAHEDRON TO SEE HOW THIS WORKS-IF YOU DON'T KNOW"
1050  PRINT "WHAT A DODECAHEDRON IS, ASK SOMEONE)"
1060  PRINT
1070  PRINT "     HAZARDS:"
1080  PRINT " BOTTOMLESS PITS - TWO ROOMS HAVE BOTTOMLESS PITS IN THEM"
1090  PRINT "     IF YOU GO THERE, YOU FALL INTO THE PIT (& LOSE!)"
1100  PRINT " SUPER BATS - TWO OTHER ROOMS HAVE SUPER BATS. IF YOU"
1110  PRINT "     GO THERE, A BAT GRABS YOU AND TAKES YOU TO SOME OTHER"
1120  PRINT "     ROOM AT RANDOM. (WHICH MIGHT BE TROUBLESOME)"
1130  PRINT
1140  PRINT "     WUMPUS:"
1150  PRINT " THE WUMPUS IS NOT BOTHERED BY THE HAZARDS (HE HAS SUCKER"
1160  PRINT " FEET AND IS TOO BIG FOR A BAT TO LIFT).  USUALLY"
1170  PRINT " HE IS ASLEEP. TWO THINGS WAKE HIM UP: YOUR ENTERING"
1180  PRINT " HIS ROOM OR YOUR SHOOTING AN ARROW."
1190  PRINT "     IF THE WUMPUS WAKES, HE MOVES (P=.75) ONE ROOM"
1200  PRINT " OR STAYS STILL (P=.25). AFTER THAT, IF HE IS WHERE YOU"
1210  PRINT " ARE, HE EATS YOU UP (& YOU LOSE!)"
1220  PRINT
1230  PRINT "     YOU:"
1240  PRINT " EACH TURN YOU MAY MOVE OR SHOOT A CROOKED ARROW"
1250  PRINT "   MOVING: YOU CAN GO ONE ROOM (THRU ONE TUNNEL)"
1260  PRINT "   ARROWS: YOU HAVE 5 ARROWS. YOU LOSE WHEN YOU RUN OUT."
1270  PRINT "   EACH ARROW CAN GO FROM 1 TO 5 ROOMS. YOU AIM BY TELLING"
1280  PRINT "   THE COMPUTER THE ROOM#S YOU WANT THE ARROW TO GO TO."
1290  PRINT "   IF THE ARROW CAN'T GO THAT WAY (IE NO TUNNEL) IT MOVES"
1300  PRINT "   AT RAMDOM TO THE NEXT ROOM."
1310  PRINT "     IF THE ARROW HITS THE WUMPUS, YOU WIN."
1320  PRINT "     IF THE ARROW HITS YOU, YOU LOSE."
1330  PRINT
1340  PRINT "    WARNINGS:"
1350  PRINT "     WHEN YOU ARE ONE ROOM AWAY FROM WUMPUS OR HAZARD,"
1360  PRINT "    THE COMPUTER SAYS:"
1370  PRINT " WUMPUS-  'I SMELL A WUMPUS'"
1380  PRINT " BAT   -  'BATS NEARBY'"
1390  PRINT " PIT   -  'I FEEL A DRAFT'"
1400  PRINT ""
1410  RETURN
2000  REM-PRINT LOCATION & HAZARD WARNINGS
2010  PRINT
2020   FOR J=2 TO 6
2030    FOR K=1 TO 3
2040    IF S(L(1),K)#L(J) THEN 2110
2050    GOTO J-1 OF 2060,2080,2080,2100,2100
2060    PRINT "I SMELL A WUMPUS!"
2070    GOTO 2110
2080    PRINT "I FEEL A DRAFT"
2090    GOTO 2110
2100    PRINT "BATS NEARBY!"
2110    NEXT K
2120   NEXT J
2130  PRINT "YOU ARE IN ROOM "L(1)
2140  PRINT "TUNNELS LEAD TO "S(L,1);S(L,2);S(L,3)
2150  PRINT
2160  RETURN
2500  REM-CHOOSE OPTION
2510  PRINT "SHOOT OR MOVE (S-M)";
2520  INPUT I$
2530  IF I$#"S" THEN 2560
2540  O=1
2550  RETURN
2560  IF I$#"M" THEN 2510
2570  O=2
2580  RETURN
3000  REM-ARROW ROUTINE
3010  F=0
3020  REM-PATH OF ARROW
3030  DIM P(5)
3040  PRINT "NO. OF ROOMS(1-5)";
3050  INPUT J9
3060  IF J9<1 OR J9>5 THEN 3040
3070   FOR K=1 TO J9
3080   PRINT "ROOM #";
3090   INPUT P(K)
3095   IF K <= 2 THEN 3115
3100   IF P(K) <> P(K-2) THEN 3115
3105   PRINT "ARROWS AREN'T THAT CROOKED - TRY ANOTHER ROOM"
3110   GOTO 3080
3115   NEXT K
3120  REM-SHOOT ARROW
3130  L=L(1)
3140   FOR K=1 TO J9
3150    FOR K1=1 TO 3
3160    IF S(L,K1)=P(K) THEN 3295
3170    NEXT K1
3180   REM-NO TUNNEL FOR ARROW
3190   L=S(L,FNB(1))
3200   GOTO 3300
3210   NEXT K
3220  PRINT "MISSED"
3225  L=L(1)
3230  REM-MOVE WUMPUS
3240  GOSUB 3370
3250  REM-AMMO CHECK
3255  A=A-1
3260  IF A>0 THEN 3280
3270  F=-1
3280  RETURN
3290  REM-SEE IF ARROW IS AT L(1) OR L(2)
3295  L=P(K)
3300  IF L#L(2) THEN 3340
3310  PRINT "AHA! YOU GOT THE WUMPUS!"
3320  F=1
3330  RETURN! 
3340  IF L#L(1) THEN 3210
3350  PRINT "OUCH! ARROW GOT YOU!"
3360  GOTO 3270
3370  REM-MOVE WUMPUS ROUTINE
3380  K=FNC(0)
3390  IF K=4 THEN 3410
3400  L(2)=S(L(2),K)
3410  IF L(2)#L THEN 3440
3420  PRINT "TSK TSK TSK- WUMPUS GOT YOU!"
3430  F=-1
3440  RETURN
4000  REM- MOVE ROUTINE
4010  F=0
4020  PRINT "WHERE TO";
4030  INPUT L
4040  IF L<1 OR L>20 THEN 4020
4050   FOR K=1 TO 3
4060   REM- CHECK IF LEGAL MOVE
4070   IF S(L(1),K)=L THEN 4130
4080   NEXT K
4090  IF L=L(1) THEN 4130
4100  PRINT "NOT POSSIBLE -";
4110  GOTO 4020
4120  REM-CHECK FOR HAZARDS
4130  L(1)=L
4140  REM-WUMPUS
4150  IF L#L(2) THEN 4220
4160  PRINT "...OOPS! BUMPED A WUMPUS!"
4170  REM-MOVE WUMPUS
4180  GOSUB 3380
4190  IF F=0 THEN 4220
4200  RETURN
4210  REM-PIT
4220  IF L#L(3) AND L#L(4) THEN 4270
4230  PRINT "YYYIIIIEEEE . . . FELL IN PIT"
4240  F=-1
4250  RETURN
4260  REM-BATS
4270  IF L#L(5) AND L#L(6) THEN 4310
4280  PRINT "ZAP--SUPER BAT SNATCH! ELSEWHEREVILLE FOR YOU!"
4290  L=FNA(1)
4300  GOTO 4130
4310  RETURN
5000  END
```
