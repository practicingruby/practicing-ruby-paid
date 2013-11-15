http://www.atariarchives.org/bcc1/showpage.php?page=247

http://en.wikipedia.org/wiki/Hunt_the_Wumpus

http://scv.bu.edu/miscellaneous/Games/wumpus.html


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

