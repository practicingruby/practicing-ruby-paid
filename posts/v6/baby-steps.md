No matter what path you took in order to become a programmer, your first 
useful software project was probably the end result of many hard nights 
and weekends of dedicated practice. Like any other complicated set of skills,
learning how to master the art of programming can be very rewarding, but 
it can also be downright exhausting at times.

To get to where you are now, the raw enthusiasm and dedication that carried
you through the beginners phase could not possibly have faded away. But to 
become an experienced programmer is to realize that there simply are not enough
nights and weekends in a lifetime to learn all the things we wish we could.
Because some degree of specialization is necessary in order to be productive, it
is impossible for your skillset to grow in a perfectly balanced way.

Every programmer needs to accept this unpleasant tradeoff between learning
everything they possibly can and getting stuff done, and so we tend to accumulate 
many technical blindspots throughout our careers. The more free time we have,
the less likely we are to notice this hard limitation, but we all end up hitting
the same brick wall in the end. As I've learned through personal experience,
nothing accelerates this process faster than trying to start a family: once
you do that, your whole approach towards learning needs to change. But as I
said, everyone will feel this tension sooner or later, so it makes sense to
learn how to deal with it regardless of what your ambitions in life are. 

We all have different gaps in our knowledge, but one of the big ones for me has
been web development skills, particularly full-stack Rails programming. In this
article, I will use this weakness of mine to demonstrate to you how I tend to
work when I am outside of my comfort zone, especially now that I have very
little free time in my life for nonessential exploratory coding. My hope is that
you'll be able to try out these ideas in your own studies so that you can
overcome your own fears of the things that lie beyond your own comfort zone.

### Body

Probably need to dump more notes!

- this is an article about how to build a side project in lots of small time
  chunks (30-90 mins at a time)

- many folks have work and family life that is too busy (myself included), and
  so we never build the things we want to build. But it's because we think we
  need large time cycles to do things.

- working in smaller chunks has its advantages and disadvantages. It does feel
  *slow*, but going slow on purpose also helps you be patient with unexpected 
  problems.

- The key is to work on finding the shortest path to something useful, i.e.
  always be shipping: every day, you should either improve the functionality in
  some tiny way, or you should set up an experiment to help you learn what you
  need to know to move forward.

- Each day should be a small, self-contained experiment that can live or die on
  its own. Don't plan work that can't be done in the time you have (30-90 mins)

- Essential to start with a single feature and refine, refine, refine around
  that central feature. Otherwise you end up with too many choices, and too many
  threads to pull on at the same time.

### My Rails experience:

The kinds of things I used to do as a consultant:

* Build a sinatra wrapper around a Windows-based DLL for a truck routing program
* Embed a Lua interpreter into a Rails application to support custom reporting formulas.
* Import data from a motley combination of CSV, Excel, XML, and scraped HTML
  files and then generate a report based on that information
* Implement Chess-like ratings for a trivia website
* Validate various forms of barcodes from retail items

In other words, most of this work has to do with building infrastructure,
computational models, and reports that end up being used within Rails
applications, but it is not really web-development work.

I actually have worked *within* Rails apps throughout most of my career, but
nearly always with the help of a designer and frontend developer, or in cases
where I had to do the work myself, someone who I could help-vampire to death.

So I am fairly familiar with Rails, but the surface of my experience is like
swiss cheese: holes everywhere.

In particular, I can usually follow the patterns that have been laid out in an
existing Rails app, but it has been years since I had to think about all the
up-front decisions that come along with getting from "rails new" to a first
shipped feature.

This amazingly has been a weakness I could work around throughout my career, but
one that always bugged me. My work on ShipItDaily was an modest attempt to overcome
that limitation.

### Session 0:  

A month ago I made a horrible set of wireframes describing how the app should
work, and had a conversation w. Jia about it. I experimented with omniauth a
little at the time, but otherwise gave up because I was *too busy*

### Session 1: (Usable prototype implemented and shown to others, but not *useful* yet)

I had a skeletal app deployed on Heroku that implemented the basic
workflow for my application. It had no authentication or database, and stored
all data in cookies.

### Session 2:

I hacked together some terrible database modeling: Identity was still determined
by session keys, but the goal data was stored in the database.

Goals are deleted when completed, and only goals created within the last 24
hours are visible. This supports the workflow I want, but is a crazy way of
doing things.

### Session 3: (Asked others to test this)

Added omniauth for twitter, placing the entire app behind an auth wall since
landing page is YAGNI for now. Also got omniauth developer mode working in
development.

### Session 4:

Fixed data model to maintain a complete history of goals rather than 0-1 
per person. The distinction between these two models is indistinguishable
via the UI, but this was bothering me. (At this stage, I am still only
displaying a goal if it was created in the last 24 hours)  

### Session 5: (This is when I start planning the Mendicant code review)

Added basic twitter bootstrap styling -- only enough to make it so the UI 
isn't completely unstyled and frustrating, not aiming to be pretty.

### Session 6: (This is where the app starts becoming useful for me)

I learned about heroku scheduler and set up some reminder emails that are
hard-coded to run at a particular time each day. These emails are static and
simply nag me to enter a goal if I haven't yet in the morning, and to mark a
goal as finished or abandoned if I haven't yet at the end of the day.

But it's here the app starts being useful: It reminds me of its existence, and
helps me start developing a habit of entering my goals into it.

This is a great turning point in any application, because it means that now
actual pain points from use will push forward development, rather than
speculative coding on things we *think* will be useful.

### Session 7: 

Dropped the 24 hour time limit for now. That was meant to put pressure on me to
finish a goal in 24 hours, but it seems like a self-imposed rule for that works
okay. Will consider bringing this back later if needed.

### Session 8: (This is where I start trying to work in too big of chunks)

Added a basic preferences page, allowing email and timezone to be set. I wanted
to implement the full application configurable, timezone-agnostic scheduling
mechanism, but it took a lot of research to just know how to integrate timezones
in a Rails app, and so I reduced scope greatly here.

### Session 9:

Added start and reminder time preferences to the settings page, and computed
time offsets (in UTC) based on timezones. Thinking through this modeling was
complicated, so once again, I didn't end up integrating it all into the reminder
tasks.

### Session 10:

Decided after trying and failing to come up with a non-horrible model for doing
recurring reminders that I would go back and radically simplify the time
modeling by only giving hourly level granularity in UTC offsets. I am not sure
if this is actually a hard modeling problem, or if it just hit my blindspots,
but in an app that I'm largely only intending to use for myself, it doesn't make
sense to seek perfectly comfortable globalization if simply storing a single
integer (`reminder_hour`) in UTC will still make it possible for anyone to use
the system.

This is the moment where I realized that I had been badly nerd sniping myself
out of fascination with the time modeling and a deep desire to "get it right",
and that it had cost me three sittings that could have gone to moving the app

### Session 11:

In preparation for the code review (and to sort of 'wrap up' the current cycle
of work on this project), I went through and tweaked the styling and workflow to
the point where I was happy with it. Being a tiny appliance, I'm still not
looking for beautiful or perfect, but being something I intend to use every day,
I don't want to be annoyed by it either. So in that sense, tying up loose ends
is worthwhile.

## Session 12

Add a few integration tests, because I know that if and when I start working on
this app again, it will be much easier to work in a test-driven workflow (or at
least a workflow that *includes* automated testing (i.e. not cowboy coding) if
there is already some tests working and the environment is set up properly.

BENEFITS

* Useful (even if in a small way), especially considering the smallish time investment
* Taught me a LOT about basic Rails dev that I had forgotten or never learned.
* Got me over the fear of working on a greenfield Rails app
* Paved the way to make it MUCH easier for me to try out new ideas in the future
* Gave me a toy that I can keep improving and tweaking over time -- it's much
easier to incrementally improve something once you're actually using it.




(note, keep syncing journal notes as needed)

http://www.elabs.se/blog/36-working-with-time-zones-in-ruby-on-rails

The general process of working in atomic slices has been very nice -- it
prevents the temptation to rush through things, and makes it easier to cope with
stumbling blocks along the way. There is no big checklist to try to clear each
day, and so failures seem more tolerable when they are isolated. If one day goes
poorly, we can switch directions the next day and start fresh in a new area.

The process also makes it easier to learn from failures and difficulties rather
than trying to simply overcome them so that you can move on to the next thing.
If a feature turns out to be harder to implement than expected, you can go back
to the big picture planning and think about whether it should be reduced in
scope, cut, or deferred. (Why is this different than ordinary "multiple changes
per day" work? Hard to verbalize :-/)

--------------------------------------------------------------------------------

Around the point in time where I started working on the reminder mailer, I
started to feel a bit of the ill effects of cowboy coding rather than having a
more structured (i.e. test-driven) flow. But since I was still trying to figure
out the requirements of the project at that time, I was hesitant to formalize my
efforts -- I wanted to focus on the product, not the code.

--------------------------------------------------------------------------------

Working on the timezone support and storage of reminder times reminded me how
much I hate anything to do with temporal logic. After looking around at some
options, I decided to use the ugly Time.zone = ... before_filter which has
global side effects (but those are mitigated because we're not processing
concurrent requests, right?), and to record reminder times as integer offsets
rather than text fields or time fields. All of this feels like ugly hackery. :-/

Also got really hung up with form helpers for time entry, ultimately ended up
just using a text field which I plan to validate later. This is what ate a huge
chunk of my time on this feature though.

--------------------------------------------------------------------------------

Gave up on time zone math temporarily, because I was struggling with figuring
out how to synchronize the scheduler. Instead requiring hourly level of
granularity in UTC only. Could be worth going back and researching how to deal
with time correctly, and then writing an article (or even an eBook) on it.

I should have done this two days ago, rather than trying to solve the hard
problem first. Could have spent two more days on improving other features rather
than trying and failing on this one. ---UNDERSCORE THIS POINT IN ARTICLE ---

Most importantly, this is a matter of a tiny inconvenience, not a fundamental
limitation in functionality. Each user will need to look up their UTC offset at
most twice per year, and this is a side project mostly for my own personal 
use anyway.

-------------------------------------------------------------------------------

Stepped through the workflow of the app a few times and smoothed some of the
rough edges. I was originally going to also add email confirmation, but figured
YAGNI. Also wanted to add a "log out" button, but figured also YAGNI, since the
entire app is behind an auth wall, but this makes it cumbersome to switch
twitter accounts while using it. Not sure how to solve it, aside from a weird
"reset" button. Maybe deal with this when it's out of prototype mode?

At this point, the app has a fairly cohesive (if simplistic) feature set. Adding
any kind of historical view of data may require a bunch of secondary features,
such as content editing (rather than simply "giving up") and goal deletion,
among other things. But we'll treat those all as "problems for later" ;-)

-------------------------------------------------------------------------------

Got www.shipitdaily.com working, but annoyed by this heroku limitation:
https://devcenter.heroku.com/articles/avoiding-naked-domains-dns-arecords

