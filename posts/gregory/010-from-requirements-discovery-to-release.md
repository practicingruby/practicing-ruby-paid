Every time we start a greenfield software project, we are faced with the overwhelming responsibility of creating something from nothing. Because the path from the requirements discovery phase to the first release of a product has so many unexpected twists and turns, the whole process can feel a bit unforgiving and magical. This is a big part of what makes programming hard, even for experienced developers.

For the longest time, I relied heavily on my intuition to get myself kick-started on new projects. I didn't have a clear sense of what my creative process actually was, but I could sense that my fear of the unknown started to melt away as I gained more experience as a programmer. Having a bit of confidence in my own abilities made me more productive, but not knowing where that confidence came from made it impossible for me to cultivate it in others. Treating my creative process as a black box also made it impossible for me to compare my approach to anyone else's. Eventually I got fed up with these limitations and decided I wanted to do something to overcome them.

My angle of approach was fairly simple: I decided to take a greenfield project from the idea phase to an initial open source release while documenting the entire process. I thought this might provide a useful starting point for identifying patterns in how I work, and also provide a basis of comparison for other folks as well. As I reviewed my notes from this exercise and compared them to my previous experiences, I was thrilled to see a clear pattern did emerge. This article summarizes what I learned about my own process in the hopes that it might also be helpful to you.

### Brainstorming for project ideas

A few days before writing this article, I was actually trying to come up with ideas for another Practicing Ruby article I'm planning on writing. I wanted to do something on event-driven programming and thought that some sort of tower defense game might be a fun example to play with. However, the ideas I had in mind were too complicated, and so I gradually simplified my game ideas until they turned into something vaguely resembling a simple board game.

Eventually I forgot that my main goal was to get an article written and decided to focus on developing my board game ideas instead. With my wife's help, I managed over the course of a weekend to come up with a fairly playable board game which beared no resemblence to a tower defense game and would serve as a terrible event-driven programming exercise. However, I still wanted to implement a software version of the game because it would make it much easier for us to analyze and share with others.

My intuition said that the project was something that would take me a day or so to build, and that it'd be sufficiently interesting to take notes on for my "documenting the creative process" exercise. This was enough to convince me to take the plunge, and so I cleared the whiteboards in my office in preparation for an impromptu design session.

### Establishing the 10,000 foot view

The difference betweeen inventing a new game and implementing an existing one is that you need to come up with a whole new vocabulary to describe your game elements and actions. We were able to cheat a little bit while playing face to face with a physical board, so I didn't realize just how informal our ruleset was until I decided to implement a software version of the game. I immediately sketched out the important components and actions and defined them before going any farther.

<div align="center">
![Sketch of game elements and actions](http://farm7.static.flickr.com/6229/6283525185_35bd4c96a8_z.jpg)
</div>

### Picking some low hanging fruit

### Laying out some scaffolding

### Starting to chip away at the hard parts

### Slamming into the wall

### Searching for a pragmatic middle path

### Shipping the 0.1.0 release

  - establish the purpose of this release
  - identify blockers

### Reflections

Had to cut a 0.1.1 ;)




The 10,000 foot view
-------------------------------------------------------

**** come up with a name [stackwars]

**** whiteboards
  - establish a vocabulary
  - establish requirements
  - establish major objects and their relationships


Solve an easy problem
------------------------------------------------------------

**** build up some fixture data (example battlefields)

## Empty board
  - can test baseline reinforcement
  - can test order of play
  - can test movement
  - would be annoying to test combat

## board with several armies already placed
  - can test attack
  - can test field reinforcements
  - can test invasion
  - can test coup attempts (end game conditions)

**** Ask question about representation:
https://gist.github.com/1310883

***** Come up with an ascii visualization
- decide on coordinate system
- decide on input

**** Hack together a formatting script as a proof of concept

Get some structure in place
------------------------------------------------------------

**** Hack together a bin/stackwars-viewer

- StackWars::TextDisplay.new(battlefield).render

- Add gemfile and gemspec (to make using executable easier)
- Copy these from another project (rcat)
- add version file

- Introduce StackWars::Battlefield container (still no tests)

**** Push to github YAY!!!!!

Look an entry point into the harder problems
------------------------------------------------------------

**** write some pseudo code for Game#move(pos1, pos2) and Game#fortify(pos)

**** write Game#fortify using mocks

**** write Territory basics and play with it in irb, then 
       use stackwars-viewer as an informal integration test

*** write Territory#fortify and tests, tests get unwieldy

*** write Territory#fortify example and find small bug: Display is white border at bottom, should be at top

*** rewrite Game#fortify as Game#play in preparation for adding MOVE and ATTACK support

Reach a breaking point
------------------------------------------------------------

*** Code lots without tests for proof of concept. Need more validations!
-  still seeding an empty battlefield via JSON, that seems like a bad idea

*** Sit Jia down for some play testing to uncover bugs and missing validations. (needed a change of pace)

[this is where I start doing cleanup chores to duck the real problem]

*** Get development dependencies properly sorted

*** Remove game tests because they were no longer really relevant

*** IllegalMove error should not be raised below the "Game" level. Other errors should be raised

*** Need to sleep because I'm rushing this...

Seek a pragmatic middle path
------------------------------------------------------------

*** simplified field: 

data = "#{File.dirname(__FILE__)}/../test/fixtures/active_battlefield.json"
field = StackWars::Battlefield.from_json(data)
game  = StackWars::Game.new(field)
game.active_player.instance_variable_set(:@reserves, 2)
game.opponent.instance_variable_set(:@reserves, 2)

Screenshots ( raise Errors::IllegalMove unless from.occupied_by?(active_player) )

*** FINALLY GOT THE END GAME CONDITIONS WORKING

*** Breakthrough in testing! Recorded a sample game.

*** Create a JSON version:

    filename = "sample-moves.txt"
    moves    = File.foreach(filename)

    data = []

    loop do
      md = moves.next.match(/^ *(?<pos1>\d+ +\d+) *(?<pos2>\d+ +\d+)? *$/)

      if md[:pos2]
        data << [md[:pos1].scan(/\d+/).map(&:to_i), md[:pos2].scan(/\d+/).map(&:to_i)]
      else
        data << [md[:pos1].scan(/\d+/).map(&:to_i)]
      end
    end

    puts data.to_json
    
*** create tests/integration/full_game_test.rb
      Fix fantastically broken other tests!

Start thinking about shipping
------------------------------------------------------------

** flip-flop about stackwars command line version / decide to go for it

*** go into cleanup mode

 - drop stackwars-viewer
 - drop fortify example
 - drop hack folder
 - make some minor edits to various files
 - drop mocha
 
*** build command line application

Basic idea:

stack_wars              # plays a game
stack_wars demo  # plays the sample game
stack_wars rules   # displays the list of rules


*** introduce /  test drive TextClient

** improve example
** implement bin/stack_wars

** write README and RULES
** add a LICENSE


SHIP IT MOTHERFUCKER!
------------------------------------------------------------

** build gem and release!
