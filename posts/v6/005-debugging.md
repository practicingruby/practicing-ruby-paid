*This article was contributed by Carol Nichols
([@carols10cents](http://twitter.com/carols10cents),
[carols10cents@rstat.us](https://rstat.us/users/Carols10cents)), one of the
active maintainers of [rstat.us](https://rstat.us). Carol is also involved in
the Pittsburgh Ruby community, and is a co-organizer of the [Steel City Ruby
Conf](http://steelcityrubyconf.org/). She is currently employed at [Think
Through Math](http://www.thinkthroughmath.com/) doing Rails development.*

Most of us who consider ourselves software developers are
more like software whisperers. We don't spend most of our time creating new
code from scratch on greenfield projects -- we're much more likely to be
up to our elbows in existing spaghetti code, trying to figure out why it isn't working 
the way we expect it to.

Considering that we spend so much time on finding and fixing bugs and dealing
with bad behavior, it is surprising that we don't discuss these issues more
often. Most knowledge of debugging techniques is gained
through direct experience, and it is rarely focused on in beginning programming
lessons. Not feeling in control of the code you write is part of what makes
programming scary to beginners and frustrating to developers of all skill
levels.

Developing a systematic way of getting out of sticky situations is an essential
part of becoming a better programmer, and it mostly boils down to having a
disciplined troubleshooting process. This article will cover some of the basic tools
and techniques that can help you improve your debugging skills, which will
help you maintain confidence even when things go wrong.

## Don't Panic

Whenever something breaks, it can be hard to remain calm. Debugging
often occurs when production is down, customers are experiencing a problem, and
managers are asking for status updates every five minutes. In this situation, panicking
is a natural response, but it can easily disrupt your troubleshooting process. It may
lead to changing code on hunches rather than on evidence or writing
untested code. By rushing to fix things immediately, you may make
the problem worse or not know which of your changes actually
fixed the problem.

If external pressures are causing you to panic, first disable
the feature that is causing the problem, or roll the code back to a known
stable state. Then work on recreating the issue in a staging environment. Even
if it isn't ideal from a usability standpoint, functioning software with a
few missing features is still more useful than unstable and potentially
dangerous software.

> Editor's Note: *Don't Panic* is the motivating
> force behind several of the maintenance policies for practicingruby.com. For
> more on this topic, see Lessons 4 and 5 from [Issue
> 5.6](https://practicingruby.com/articles/91)

## Narrow Down the Problem

Even the most trivial piece of software can involve an infinite number of
interacting components, from the web browser down to the hardware. In order to
be able to fix a problem, you need to narrow down the involved components to
those that are proven to be causing the issue. Start with a way to reproduce
the problem: this may be an automated test, a script, or a set of manual steps.
From there, you can try to reproduce the problem with fewer components involved, 
repeating the process until you have pinpointed the problem. Depending on the
kind of problem you're dealing with, you may choose to investigate using a
top-down approach, a bottom-up approach, or some combination of the two:

**Top-down investigations** start with an end-to-end reproduction followed
by gradual isolation of components. For example, if working with a Rails app and a set of user actions
that cause a bug, you could try to eliminate the web browser by reproducing the 
issue in the Rails console. Or if the problem is occurring in a long method, you
might log some relevant values about halfway through the long method to 
determine if the issue is due to code in the first half of the method or the 
second half. This basic divide-and-conquer strategy can be used at any level
of your system, and it is similar to performing a binary search in that
each new step breaks the problem space down into smaller and smaller chunks.

**Bottom-up investigations** tend to start with a new file or new
environment and involve writing the least amount of code possible to
recreate the issue you're seeing in your existing software. For example,
if you had an issue with a newly introduced dependency in a project,
you might try creating a minimal example using only the gems involved
in the particular problem and then try to reproduce the bad behavior
with as few actions as possible. Similarly, if you expect that bad
data might be to blame for a problem in your program, you could start 
with an empty database and introduce only the records necessary 
to reproduce the issue you're investigating. In both cases, this process
allows you to remove many components from consideration by never involving
them in the first place.

Deciding whether to use the top-down or bottom-up approach depends on the
particulars of your situation. The top-down approach tends to work well when you
suspect that the problem is within your own code and you don't know exactly
where it might be, while the bottom-up approach is very effective at dealing
with issues that arise along the borderlines between your own code and
third-party components. However, when dealing with complicated bugs in large
systems, it's not uncommon to combine the two approaches as you incrementally
work your way through the problem space. As long as each step of your
investigation helps you narrow things down, there's nothing wrong with using a
multi-faceted strategy.


## Read Stack Traces

Stack traces are ugly. They typically present themselves as a wall of text 
in your terminal when you aren't expecting them. When pairing, I've often seen people
ignore stack traces entirely and just start changing the code. But stack
traces do have valuable information in them, and learning to pick out the
useful parts of the stack trace can save you a lot of time in trying to narrow
down the problem.

The two most valuable pieces of information are the resulting error message
(which is usually shown at the beginning of the stack trace in Ruby) and the
last line of your code that was involved (which is often in middle). The
error message will tell you *what* went wrong, and the last line of your
code will tell you *where* the problem is coming from.

A particularly horrible stack trace is [this 1400 line trace](https://gist.github.com/carols10cents/4751381/raw/b75bdb41e7fa8ded54d13dc786808b464357effe/gistfile1.txt)
from a Rails app using JRuby running on websphere. In this case, the error message
*"ERROR [Default Executor-thread-15]"* is not very helpful. The vast majority of the lines are
coming from JRuby's Java code and are also uninformative. However, skimming
through and looking for lines that don't fit in, there are some lines that are
longer than the others (shown wrapped and trimmed below for clarity):

```
rubyjit.ApplicationHelper
  $$entity_label_5C9C81BAF0BBC4018616956A9F87C663730CB52E.
  __file__(/..LONGPREFIX../app/helpers/application_helper.rb:232)
  
rubyjit.ApplicationHelper
  $$entity_label_5C9C81BAF0BBC4018616956A9F87C663730CB52E
  .__file__(/..LONGPREFIX../app/helpers/application_helper.rb)
```

These lines of the stack trace point to the last line of the Rails code that
was involved, line 232 of *application_helper.rb*. But this particular line
of code was simply concatenating two strings together, which made it pretty
clear that the problem was not caused by our application code! By trying
various  values for those strings, we eventually found the cause of the
problem: [an encoding-related bug](https://github.com/jruby/jruby/issues/366) in
JRuby was causing a Ruby 1.9 specific feature to be called from within Ruby 1.8
mode. Even though our stack trace was very unpleasant to read and did not
provide us with a useful error message, tracing the exception down to a
particular line number was essential for identifying what would have otherwise
been a needle in a haystack.

Of course, there are some edge cases where line numbers are not very helpful. One is
the dreaded *"syntax error, unexpected $end, expecting keyword_end"* error, which
will usually point to the end of one of your files. It actually means you're
missing an `end` somewhere in that file. However, these situations are rare, and
so it makes sense to skim stack traces for relevant line numbers
that might give you a clue about where your bug is coming from.

If all else fails, you can always try doing a web search for the name of the
exception and its message -- even if the results aren't directly related to your
issue, they may give you useful hints that can help you discover the right
questions to ask about your problem.

## Use debuggers

Debugging tools (such as ruby-debug) are useful because they allow you to inspect your code and its 
environment while it's actually running. However, this is also true about using
a REPL (such as irb), and many Rubyists tend to strongly prefer the latter
because it is a comfortable workflow for more than just troubleshooting.

The [Pry](http://pryrepl.org/) REPL is becoming increasingly popular, because it
attempts to serve as both a debugger and an interactive console simultaneously.
Placing the `binding.pry` command anywhere in your codebase will launch you into
a Pry session whenever that line of code is executed. From there, you can do
things like inspect the values in variables or run some arbitrary code. Much like 
irb, this lets you try out ideas and hypotheses quickly. If you can't easily
think of a way to capture the debugging information you need with some simple
print statements or a logger, it's a sign that using Pry might get you 
somewhere.

This kind of workflow is especially useful when control flow gets complicated,
such as when working with events or threads. For example, suppose we wanted to
get a closer look at the behavior of [the actor model](https://github.com/elm-city-craftworks/practicing-ruby-examples/blob/master/v6/003/lib/actors.rb)
from the Dining Philosopher's problem from [Issue 6.3](https://practicingruby.com/articles/100). 
Here's how we would inspect what's happening in the `Waiter#request_to_eat`
method:

```ruby
require "pry"

class Waiter
  # ...

  def request_to_eat(philosopher)
    binding.pry
    return if @eating.include?(philosopher)

    @eating << philosopher
    philosopher.async.eat
  end
end
```

Because the `Waiter` class is an actor, it will execute the requests to eat in
sequence, but they will be queued up asynchronously. As soon as one is
actually executed, we will be dropped into a Pry session:

```console
From: (..)/dining_philosophers.rb @ line 61 Waiter#request_to_eat:

    60: def request_to_eat(philosopher)
 => 61:   binding.pry
    62:   return if @eating.include?(philosopher)
    63:
    64:   @eating << philosopher
    65:   philosopher.async.eat
    66: end

[1] pry(#<Waiter>)>
```

From here, we can deeply interrogate the current state of our program,
revealing that the `philosopher` references an `Actor::Proxy` 
object, which in turn wraps a `Philosopher` object 
(Schopenhauer in this case):

```
# NOTE: this output cleaned up somewhat for clarity

[1] pry(#<Waiter>)> ls philosopher
Actor::Proxy#methods: async  method_missing  send_later  terminate
instance variables: @async_proxy  @mailbox  @mutex  @running  @target  @thread
[2] pry(#<Waiter>)> cd philosopher/@target
[3] pry(#<Philosopher>):2> ls
Philosopher#methods: dine  drop_chopsticks  eat  take_chopsticks  think
self.methods: __pry__
instance variables: @left_chopstick  @name  @right_chopstick  @waiter
locals: _  __  _dir_  _ex_  _file_  _in_  _out_  _pry_
[4] pry(#<Philosopher>):2> @name
=> "Schopenhauer"
[5] pry(#<Philosopher>):2> cd
[6] pry(#<Waiter>)> @eating.count
=> 0
```

Once we're ready to move on to the next call to `request_to_eat`, we simply call
`exit`. That immediately launches a new console that allows us to determine
that Schopenhauer's is already in the `@eating` queue by the time Aristotle's request
is starting to be processed:

```
[1] pry(#<Waiter>)> cd philosopher/@target
[2] pry(#<Philosopher>):2> @name
=> "Aristotle"
[3] pry(#<Philosopher>):2> cd
[4] pry(#<Waiter>)> @eating.count
=> 1
[5] pry(#<Waiter>)> cd @eating.first/@target
[6] pry(#<Philosopher>):2> @name
=> "Schopenhauer"
```

Imagine for a moment that there was a defect in this code. Replicating this 
exact situation in a test where we can access the values of
`@eating` and the internals of the `philosopher` argument at these 
particular points in the execution would
not be straightforward, but Pry makes it easier to casually poke at these
values as part of an ad-hoc exploration. If there was a bug to be found here,
Pry could help you identify the conditions that trigger it, and then other
techniques could be used to reproduce the issue once its root cause
was discovered.

This particular use case merely scratches the surface of Pry's capabilities-- 
there are many commands that Pry provides that are powerful tools for inspecting your
code while it's running. That said, it is not a complete substitute for
a traditional debugger. For example, gdb can be useful for hunting down
hard-to-investigate issues such as segfaults in MRI's C code. If you're interested in that kind
of thing, you may want to check out [this talk from Heath Lilley](http://vimeo.com/54736113)
about using gdb to determine why a Ruby program was crashing.

## Lean on tests

Whenever you need to fix a bug, you're writing a test first, right? This
serves multiple purposes: it gives you a convenient way to reproduce the issue
while you're experimenting, and if added to your test suite, it will help
prevent regressions of this bug happening in this way again.

But not all tests need to be added to your test suite. While debugging, it can
be a useful way to record your discoveries and experiments. You can start with
an end-to-end integration test that is able to reproduce the problem and then
write smaller and smaller tests as you are narrowing down where the issue is
occurring until you get a unit test. Then you can fix the issue, run all the
tests to confirm the fix, and commit just the unit test along with the fix.

Some tests don't make sense to add to a test suite, especially negative
examples such as "it should not crash when given special characters". The
situation is just too specific to happen exactly that way again.

For example, here is a test that I added to
[rstat.us' codebase](https://github.com/hotsh/rstat.us/commit/26444ea95ec8da12d4e74764bf52bdaad18e7776)
about a year ago:

```ruby
it "does let you update your profile even if you use a different case in the url" do
  u = Factory(:user, :username => "LADY_GAGA")
  a = Factory(:authorization, :user => u)
  log_in(u, a.uid)
  visit "/users/lady_gaga/edit"
  bio_text = "To be or not to be"
  fill_in "bio", :with => bio_text
  click_button "Save"

  assert_match page.body, /#{bio_text}/
end
```

Rather than adding another test for the case of going to the url for username
"lady_gaga" when the username is "LADY_GAGA" (don't ask why I chose Lady Gaga,
I don't remember), I could have instead updated
[the existing happy path test](https://github.com/hotsh/rstat.us/blob/26444ea95ec8da12d4e74764bf52bdaad18e7776/test/acceptance/profile_test.rb#L45)
to encompass this situation (effectively replacing the existing happy path test
with this special case test). In this way, the special case and the happy path
are being tested, but there is less duplication.

Even though sometimes it seems like software has a mind of its own, computers
only do what a human has told them to do at some point. You **can** figure out
why a bug is happening by using deterministic processes to narrow down where the
problem is happening. You **can** learn to pick out the useful parts of stack
traces. You **can** use debuggers to experiment with what your code is
actually doing as it runs. And you **can** write tests that help you while
debugging and then turn them into useful regression tests. Go figure out some
bugs! <3

## References

* [Debug it!](http://pragprog.com/book/pbdp/debug-it) by Paul Butcher
* [Railscast on Pry](http://railscasts.com/episodes/280-pry-with-rails)
