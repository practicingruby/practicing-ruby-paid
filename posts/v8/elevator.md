> Write article like a good piece of journalism or in-depth story telling
> with technical details and code as supporting materials, moreso than a
> dry technical analysis. Ideally we'll seamlessly blend human-centric
> anecdotes with some hard math/code, in the way that a good book like
> GEB might.

# FUNDAMENTAL ASSUMPTIONS: 
 > No *external, human visible* changes to existing elevator interface
 > No expensive or complex monitoring systems (simple weight sensors OK, and similar)
 > Assume realistic human behavior, not perfect behavior
 > Assume you cannot train elevator users beyond what is already common behavior
 > Goal (for the article) is not to come up w. an optimal design, just to explore
   the topic, especially as it relates to human behavior / needs and the
   good and bad influences of technology.

- http://www.elevatorworld.com/magazine/misconceptions/

- https://www.youtube.com/watch?v=2PPgsDoyzmY
(pull out and take notes from "Lift Doctor Q+A")



- https://courses.cit.cornell.edu/ee476/FinalProjects/s2007/aoc6_dah64/aoc6_dah64/
- http://en.wikipedia.org/wiki/Elevator
- http://en.wikipedia.org/wiki/Elevator_algorithm
- http://en.wikipedia.org/wiki/LOOK_algorithm
- http://tierneylab.blogs.nytimes.com/2007/12/20/smart-elevators-dumb-people/?_r=0

- http://www.i-programmer.info/programmer-puzzles/203-sharpen-your-coding-skills/4561-sharpen-your-coding-skills-elevator-puzzle.html
(note caveat that we only have "a call from floor N", not "Number of people wanting to go to X"

- http://en.wikipedia.org/wiki/Edmonds%E2%80%93Karp_algorithm (???)
- http://www.bestoldgames.net/simtower

- https://news.ycombinator.com/item?id=3351649
- http://www.jnd.org/dn.mss/are_the_new_elevators_bad_design.html (by donald norman)
- http://tierneylab.blogs.nytimes.com/2007/12/20/smart-elevators-dumb-people/?_r=0a (references don norman)

- Look in "Design of everyday things" for relevant sections on elevators (if any)

> Optimize for average waiting time, but how to determine average waiting time reliably?
> Also, where do you draw the line and switch to other behavior?

> Real elevator user behavior is in 99% of cases: Is the direction I want to go lit up yet?
Press if not. Is my floor lit up yet? Press if not.

- Elevator traffic handbook (consider renting for Kindle, referenced in many places)

> The elevator algorithm, a simple algorithm by which a single elevator can 
> decide where to stop, is summarized as follows:
>
> Continue traveling in the same direction while there are remaining 
> requests in that same direction.
> If there are no further requests in that direction, then stop and become idle, 
> or change direction if there are requests in the opposite direction.
>
> Related:
> "Knuth, Donald, The Art Of Computer Programming. Vol 3, pp 357-360.”One tape sorting”.
> (discussed in i-programmer article) 

(Goal would probably be to start w. this algorithm and then look at the failure
cases and opportunities for optimization based on various edge case scenarios)

> Model based on as limited information as possible, i.e. what the elevator can 
"know", and avoiding very fancy technology (stick to the basic two button system)

> What kinds of metrics can be used as a proxy for user experience? What can't?

> The elevator doesn't know much (if anything) about people. But what information
can we possibly give people about the elevator??? (i.e. current floor number, direction, etc?)

> (model call buttons as very simple states: once pressed they stay lit until the elevator shows
up / reaches floor / etc, and additional button presses do nothing) 

> Consider adding a basic scale mechanism for estimating number of passengers,
> if implemented, discuss tradeoffs. 

> LOOK UP REALISTIC ELEVATOR SPEEDS / ACCELERATION?

> Have Jia help with testing for statistical significance, making sure
metrics are valid, sample sizes, etc. (There can be a post-hoc analysis
of elevator performance somehow, maybe including passenger logs --
theme: video has been recorded in all floors/elevators and analyzed
as a means of evaluating elevator algorithm performance in practice)

> Emphasize all the human-related needs / errors / quirks / corner cases to
throw the focus far afield from those who would see this as a theoretical
queue optimization problem with ideal actors and environmental conditions.
(in other words, build a mean and dirty world to test ideas in) 

> Consider separating the simulation into different processes, one that simulates
the people, and another that simulates the elevator calls / responses, to make it 
so that there is a very narrow interface between them with only limited information
sharing.

> Consider making a contest or open call for participation by giving a rudimentary
simulator with a few basic cases, and a defined interface for the elevator controller
which could be plugged into the "real" simulator and analyzed in practice.

> From the i-programmer article:
> "Of course to see the algorithm really work you need to have more floors, 
> more people and a bigger car. But the idea of getting everyone out at 
> each floor and then picking the ones going the maximum distance 
> in either the up or down direction is the key to the algorithm."
>
> Investigate if this actually does lead to good average waiting time results.
> If so, consider usability issues. 
(I.e. contrast human optimal vs. mathematical optimal result)


From NYT article:

--------------------------------------------------

> Another problem with new technology is that it’s usually introduced with
glitches. When our building opened, people kept getting off on the 
wrong floor because the elevator didn’t tell you which floor it was.
Traditional elevators tell you where you are by lighting up each floor number
as you reach it, but this elevator didn’t bother. It simply listed the next 
stops it was making. If it was stopping at floors 4 and 7, when the doors 
opened at the 4th floor, the electronic sign above the elevator doors would
be displaying 7 – and people going to the 7th floor would see it and get off.
It took months before engineers finally added a feature to the sign showing 
which floor the elevator was on.

> Every new technology has bugs in it,” Dr. Norman said. “But we compound the
problem when we devise a whole new method of doing something and
then we don’t’ work out the little details that annoy people. In some
cases they get so annoyed they don’t use the technology at all. 
But they don’t have much choice when it comes to using elevators.”

--------------------------------------------------

From Don Norman:

> If the story ended there, I would not be sharing this experience with you. 
> It turns out, I had to re-visit the same office about an hour later. 
> On the first encounter I was alone in the waiting area, so there was one elevator, 
> one person. Good, a match. The second visit however, there were a dozen people and four elevators open.
> Finally in frustration I went to the lobby security guard. I give him credit for his courtesy,
> he demonstrated that when you pad in your floor number,
> the display also shows the letter for your ride "A-J". His next comment demonstrated 
> how little people understand the problem. He said "It's easy once you get used to it". 
> It may be easy for those who work in the building, but the offices there are to serve the public.
> Most of the public visitors will only come once or twice and will never get past the learning curve.
>
> (See his reply in article)

Possible scenarios:

- "Breakfast scenario" from DC  hotel, and other "time of day" changes in traffic flow
- Broken elevator
- Moving day
- Kids playing
- Protesters flooding a location
- F**k it, I'll take the stairs (or go to the other side of the floor)
- Sabbath mode (stop at all floors)
- Other special operating modes: http://en.wikipedia.org/wiki/Elevator#Special_operating_modes
- Common user errors (in places where multiple buttons aren't all illuminated together, press them all. 
Get in the elevator when its going up even though you want to go down, hit both up and down call buttons, etc,
press wrong floor button by accident)
- Fire calls / other emergencies (i.e. hold the elevator in place or quickly move it to some other floor)
- Power outage
