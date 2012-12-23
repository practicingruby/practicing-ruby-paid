A couple months before writing this article, I came up with a very simple idea
for a tool that would help me establish daily goals and follow through with
them. The minimum feature set I had in mind wasn't anything fancy; it involved
little more than a text box that you could enter a goal into, and
scheduled emails to remind you to check in at the beginning and end of the day.
At the time, I captured the rough idea of the application in the boring
wireframe shown below:

![](http://i.imgur.com/s1LJj.png)

For most Rails programmers, building this app would be a walk in the park: 
there just isn't a lot going on here. But in my case, I had so
little experience with building Rails apps from scratch that I initially
abandoned this idea after spending an hour or so fumbling around with
getting Twitter authentication set up. Several years of specializing in building
all sorts of underplumbing for data analysis and reporting had left me heavily
dependent on having someone else handle frontend development whenever I was
writing code for web applications. In other words, I don't have a "full stack"
background, and that makes even simple projects like this hard for me.

In the past, reminding myself of how much I didn't know about web development
usually pushed me to do one of two things: Abandon the project idea, or choose a
different delivery mechanism (typically a command line application). It wasn't
so much a fear of incompetence that lead me to make those decisions as it was a
feeling that I just didn't have the time to learn the concepts properly; I
honestly believed it would be more productive to stick to what I already had 
mastered. But from an outsider's perspective, this is exactly the kind of
thinking that leads to stagnation.

## Breaking through the wall, one brick at a time 

After a month or so of working on other things, I decided to revisit this 
app idea. The problem that had lead me to think of it in the first place was still
affecting me every day, and I really wanted to do something about it. I was also
feeling a bit guilty for abandoning the idea, because the
project seemed so fundamentally simple that it was embarassing for me to not be
able to implement it with ease. Still, I knew that if I tried to set aside a big
stretch of time to work on this application (like a full weekend), it would be
very likely for me to get stuck on something that would frustrate me enough to
walk away from the project again.

Eventually, it occured to me that I should take my own advice and proceed by
working on the project in small incremental steps. I wrote about this strategy
in detail in [Issue 2.6][pr-2.6], where I took a similar approach to learning
the 2D game library Ray. In that article, I built a simple arcade game in 13
steps while using a framework that I was unfamiliar with, and in this one, I'll
show you how I did the same with a Rails application.

> **NOTE:** Those of you who find Rails code boring, don't worry: this is not 
meant to be a tutorial on how to build a Rails application. Instead, it is
meant to show a repeatable process that I have used to meaningfully 
work my way through unfamiliar territory while rapidly learning new things. As
you read through the steps I took to work through my own weaknesses, think 
about how you might break out of your own comfort zone using a similar approach.

[pr-2.6]: https://practicingruby.com/articles/6

### Step 1: Captured the core idea of the application in working code

When I first had the idea to build ShipItDaily, I committed the classic sin of
working sequentially rather than focusing on the big picture: Since
authentication was the first step in the workflow, I started there. The problem
with this approach is that it does not do much of anything to validate the
overall idea of the project, and so any failures that happen feel
more like setbacks rather than learning experiences.

Coming back to the project with fresh eyes, I decided to take a path that would
yield more of a quick win for me. That meant recreating a workflow that
resembled my initial mockups, even if it was implemented with nothing but smoke
an mirrors on the backend. With this in mind, my initial coding session yielded
the following results:

<div align="center">
<iframe width="640" height="480" src="http://www.youtube.com/embed/al1rZWQyPqE?rel=0" frameborder="0" allowfullscreen></iframe>
</div>

I obviously cut many corners here. You can tell by looking at it
that the styling is non-existent. If you peek behind the curtain, you'll find
that there isn't even a database hooked up yet:

```ruby
class HomeController < ApplicationController
  def index
    return render "shipped" if session[:shipped]
    return render "track_goal" if session[:goal]
  end

  def commit
    session[:goal] = params[:goal]
    redirect_to "/"
  end

  def shipped
    session[:shipped] = true if params[:commit][/shipped/]

    redirect_to "/"
  end

  def reset
    session[:shipped] = nil
    session[:goal] = nil

    redirect_to "/"
  end
end
```

Even as a novice web developer, I know that treating a cookie-based session as a
data store is a dangerous proposition: There are tiny fixed size limits and it's
just an all around clunky way of doing things. However, when building a
proof-of-concept, it is usually burdensome to concern yourself with real-world
issues. At this stage, the goal is to flesh out the idea, not the
implementation. Writing the code in this way helped avoid engaging the part of
my brain that obsesses over what field should go on what table in a database.

**CONSIDER ELABORATING MORE HERE**


### Step 2: Started working on very basic persistence

After building something that vaguely represented the workflow in my mockups, it
became possible to start tweaking the internals in incremental steps. This is
another mind trick: Editing always requires less resistance than writing.

At this stage I was still looking to play fast and loose: I wasn't ready to
fully flesh out the data model, but I did want to throw some persistence into
the mix. At the databse level, I put together a schema that looked like this:


```ruby
create_table "goals", :force => true do |t|
  t.text "description"
  t.boolean "completed"
  t.integer "author_id"
  t.datetime "created_at", :null => false
  t.datetime "updated_at", :null => false
end

create_table "people", :force => true do |t|
  t.text "uid"
  t.datetime "created_at", :null => false
  t.datetime "updated_at", :null => false
end
```

Having some basic persistence in place allowed me to write code that began to
look somewhat more realistic (if a bit messy):

```ruby 
class HomeController < ApplicationController
  # ...

  def index
    person = Person.find_or_create_by_uid(session[:identity])
    @goal = person.goals.where("created_at > ?", Date.today - 1).first

    if @goal && @goal.completed
      render "shipped"
    elsif @goal
      render "track_goal"
    else
      render "index"
    end
  end

  # ...
end
```

But you don't need to look far for the signs that this implementation is still
largely full of secrets and lies. For example, if you trace down when
`session[:identity]` is being set, you'll find that it is generating random
UUIDs for each session:

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :establish_identity

  def establish_identity
    session[:identity] ||= SecureRandom.uuid
  end
end
```

And if you look at how new goals are being started, you'll find that this
application truly believes that each day ought to be a blank slate:

```ruby
class HomeController < ApplicationController
  # ...

  def reset
    person = Person.find_or_create_by_uid(session[:identity])
    goal = person.goals.where("created_at > ?", Date.today - 1).destroy_all

    redirect_to "/"
  end

  # ...
end
```

Now this may seem like tom-foolery, and from a code perspective, it certainly
is. From an engineering stand point, there is no good reason for intentionally
writing code that you know is incorrect. However, the squishy little human part
of our brain is still prone to analysis paralysis in the early stages of a
project, and so every corner we cut allows us to reduce our risk of getting
bogged down in details while still making some measurable forward progress on
the parts of the code that WILL stick around.

### Step 3: Added twitter-based authentication

I'm not really a fan of Twitter, for a number of reasons. But aside from Github,
it's one of the only services that I manage to stay logged into all day, and so
it is a convenient identity provider for me. When you add into the mix the fact
that I was asking people to try out this code for me on Twitter, it seemed like
a natural fit.

I used [OmniAuth](https://github.com/intridea/omniauth) to take care of the
heavy lifting for me, and to make it easy for me to add or change identity
services later. Since the library is well documented and most Rails programmers
are bound to be familiar with it, I'll spare you the details of how I wired
things up. However, it is worth noting that because I had already started
looking up `Person` records based on unique ids stored in the user's session in
the previous step, the introduction of Twitter authentication (and OmniAuth
developer for that matter), was mostly a matter of swapping out the code that
sets those values so that it uses the data that OmniAuth provides on a
successful login, rather than a randomly generated identifier:

```ruby
class SessionsController < ApplicationController
  skip_before_filter :authorize_user, :only => :create

  def create
    Person.find_or_create_by_uid(auth_hash["uid"])
    session[:identity] = auth_hash["uid"]

    redirect_to "/"
  end

  private

  def auth_hash
    hash = request.env['omniauth.auth']
    hash['uid'] = hash['uid'].to_s

    hash
  end
end
```

No immediate changes were needed in the data model, and only superficial changes
were made to the `HomeController` in this step (namely, the introduction of a
`current_user` helper that prevents the code from having to reference
`session[:identity]` directly.

Because setting up OmniAuth properly was something that I didn't have much
experience with, I still stumbled quite a bit while introducing this feature.
However, because the basic application workflow was already in place and a
simple (albeit rough) data model already existed, the feeling of simply changing
the way a value gets set and retrieved in that model was much less daunting than
starting with rails new and figuring out how to get a page behind an auth wall
(OMG Terrible sentence ALERT!!!)

### Step 4: Improved the data model

Fixed data model to maintain a complete history of goals rather than 0-1 
per person. The distinction between these two models is indistinguishable
via the UI, but this was bothering me. (At this stage, I am still only
displaying a goal if it was created in the last 24 hours)  

### Step 5: Added bare minimum styling using Twitter bootstrap

(This is when I start planning the Mendicant code review)

Added basic twitter bootstrap styling -- only enough to make it so the UI 
isn't completely unstyled and frustrating, not aiming to be pretty.

### Step 6: Added basic email reminders

(This is where the app starts becoming useful for me)

I learned about heroku scheduler and set up some reminder emails that are
hard-coded to run at a particular time each day. These emails are static and
simply nag me to enter a goal if I haven't yet in the morning, and to mark a
goal as finished or abandoned if I haven't yet at the end of the day.

But it's here the app starts being useful: It reminds me of its existence, and
helps me start developing a habit of entering my goals into it.

This is a great turning point in any application, because it means that now
actual pain points from use will push forward development, rather than
speculative coding on things we *think* will be useful.

### Step 7: Dropped the 24 hour time limit.

Dropped the 24 hour time limit for now. That was meant to put pressure on me to
finish a goal in 24 hours, but it seems like a self-imposed rule for that works
okay. Will consider bringing this back later if needed.

### Step 8: Expose a few user preferences

Added a basic preferences page, allowing email and timezone to be set. I wanted
to implement the full application configurable, timezone-agnostic scheduling
mechanism, but it took a lot of research to just know how to integrate timezones
in a Rails app, and so I reduced scope greatly here.

### Step 9: Added reminder time preferences (minus some wiring)

Added start and reminder time preferences to the settings page, and computed
time offsets (in UTC) based on timezones. Thinking through this modeling was
complicated, so once again, I didn't end up integrating it all into the reminder
tasks.

### Step 10: Implemented configurable reminders (minus timezone support)

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

### Step 11: Refactored in preparation for a code review

In preparation for the code review (and to sort of 'wrap up' the current cycle
of work on this project), I went through and tweaked the styling and workflow to
the point where I was happy with it. Being a tiny appliance, I'm still not
looking for beautiful or perfect, but being something I intend to use every day,
I don't want to be annoyed by it either. So in that sense, tying up loose ends
is worthwhile.

## Step 12: Added some basic integration tests

Add a few integration tests, because I know that if and when I start working on
this app again, it will be much easier to work in a test-driven workflow (or at
least a workflow that *includes* automated testing (i.e. not cowboy coding) if
there is already some tests working and the environment is set up properly.

## Step 13: Made revisions based on code review feedback

Fill this in

---


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

