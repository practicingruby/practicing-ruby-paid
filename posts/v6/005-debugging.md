*This article was contributed by Carol Nichols
([@carols10cents](http://twitter.com/carols10cents),
[carols10cents@rstat.us](https://rstat.us/users/Carols10cents)), one of the
active maintainers of [rstat.us](https://rstat.us). Carol is also involved in
the Pittsburgh Ruby community, and is a co-organizer of the [Steel City Ruby
Conf](http://steelcityrubyconf.org/). She is currently employed at [Think
Through Math](http://www.thinkthroughmath.com/) doing Rails development.*

I have a hunch that most of us who consider ourselves software developers are
more like software whisperers. We do not spend most of our time creating new
code out of nothing on greenfield projects; we are up to our elbows in
existing spaghetti code, trying to figure out why it isn't doing what we want
it to do.

Debugging code to figure out the root cause, and the code modifications
necessary, to get the desired behavior of a program is something that's not
discussed nearly enough. Most knowledge of debugging techniques is gained
through direct experience, and rarely is it discussed in beginning programming
material. Not feeling in control of the code you write leads to frustration
and despair. The use of a troubleshooting process, however, can provide
systematic ways to get out of any sticky situation.

## Don't Panic

The first thing to remember when debugging code is to not panic. Debugging
often occurs when production is down, customers are experiencing a problem, and
managers are asking for status every five minutes. In this situation, panicking
is a natural response, but it's a harmful state of mind in which to be
debugging. It may lead to changing code on hunches rather than on evidence, or
skipping writing tests. Then you may end up making the problem worse, or not
knowing which of your changes actually fixed the problem.

If external pressures are making it too difficult to not panic, first disable
the feature that is causing the problem, or roll the code back to a known
stable state. Then work on recreating the issue in a staging environment. End
users would rather have the problem fixed, of course, but functioning code with
fewer features is more useful than nonfunctioning code.

## Narrow Down the Problem

Even the most trivial piece of software can involve an infinite number of
interacting components, from the web browser down to the hardware. In order to
be able to fix a problem, you need to narrow down the involved components to
those that are proven to be causing the issue. Start with a way to reproduce
the problem: this may be an automated test, a script, or a set of manual steps.
Then use either a top-down or bottom-up approach to reproduce the problem with
fewer components involved, and repeat the process until you have pinpointed the
problem.

By top-down, I mean starting from an end-to-end reproduction and eliminating
components. For example, if working with a Rails app and a set of user actions
that cause a bug, try to eliminate the web browser by reproducing the issue in
the Rails console. Or if the problem is occurring in a long method, print out
relevant values about halfway through the long method to determine if the issue
is due to code in the first half of the method or the second half. You're
essentially performing a binary search of your code.

A bottom-up approach would consist of starting with a new file or new
environment and writing the least amount of code possible to recreate the issue
you're seeing in your existing software. For example, create a brand new Rails
app, add only the gems involved in the particular problem, and write just one
action. Another way would be creating the least amount of data needed to
recreate the issue-- write a test that creates one record in the database
instead of dealing with all the records in your production database. In this
way, you're removing many components from consideration by never adding them.

Deciding whether to use the top-down or bottom-up approach depends on the
particulars of your situation. I tend to use top-down more often when trying to
find a problem that is in my own code (which it usually is!) and bottom-up when
trying to prove that a problem is in a third-party library that I'm using.

## Read Stack Traces

Stack traces are ugly. They typically present as a wall of text in your
terminal when you aren't expecting them. When pairing, I've often seen people
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
coming from JRuby's java code and are also uninformative. However, skimming
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
was involved. In this situation, on line 232 of application_helper.rb, two
strings were being concatenated. By trying various values for those strings,
we found the cause of the problem: [an encoding-related bug](https://github.com/jruby/jruby/issues/366)
in JRuby was causing a Ruby 1.9 specific feature to be called from within Ruby 1.8 
mode.

<!--
NOTE: I find this interesting because it's an example of something trying to make stack traces more useful, but I'm not sure how relevant it is:

  The Turn test formatting library actually [filters the backtrace it displays](https://github.com/TwP/turn/blob/master/lib/turn/reporter.rb#L88) of the test harness to cut down on the noise a bit.
 -->

There are some exceptions when the line numbers are not very helpful. One is
the dreaded "syntax error, unexpected $end, expecting keyword_end" error, which
will usually point to the end of one of your files. It actually means you're
missing an `end` somewhere in that file. If you're not sure what an error is
telling you, often a search for "ruby" and the error message will point you in
the right direction.

## Use debuggers

Debuggers are tools that exist for most languages that let you inspect your
code and its environment while it's actually running. Ruby has ruby-debug, and
if you hit a problem like a segfault that involves the C code in MRI, you can
also use gdb. [Heath Lilley recently did a talk at
pghrb](http://vimeo.com/54736113) about using gdb to figure out why his Ruby
program was crashing. But my favorite debugger for Ruby right now is
[Pry](http://pryrepl.org/). Once it's installed, you can insert a
`binding.pry` at the location in your code where the problem is. Then run your
code until it hits that point and you'll be placed in an interactive Pry
session. Then you can do things like inspect the values in variables or run
some code. Much like irb, this lets you try out ideas and hypotheses quickly. I
often reach for pry when I'm not sure what I want to be able to inspect-- if I
know what I want, I'll usually just print or log.

Debuggers are especially useful when it's difficult to recreate the exact
circumstances in a different context, such as when working with events or
threads. For example, take the
[Ruby implementation of the Actor model](https://github.com/elm-city-craftworks/practicing-ruby-examples/blob/master/v6/003/lib/actors.rb)
from [Issue 6.3](https://practicingruby.com/articles/100): if we want to be
able to inspect what's happening in
[`Waiter#request_to_eat`](https://github.com/elm-city-craftworks/practicing-ruby-examples/blob/master/v6/003/actors_from_scratch/dining_philosophers.rb#L59),
we can `require 'pry'` in
[`dining_philosophers.rb`](https://github.com/elm-city-craftworks/practicing-ruby-examples/blob/master/v6/003/actors_from_scratch/dining_philosophers.rb)
and add a `binding.pry`:

    def request_to_eat(philosopher)
      binding.pry
      return if @eating.include?(philosopher)

      @eating << philosopher
      philosopher.async.eat
    end

Then if we run dining_philosophers.rb, the first time that `request_to_eat` is
called we will be dropped into a pry session:

    From: /Users/carolnichols/Ruby/practicing-ruby-examples/v6/003/actors_from_scratch/dining_philosophers.rb @ line 61 Waiter#request_to_eat:

        60: def request_to_eat(philosopher)
     => 61:   binding.pry
        62:   return if @eating.include?(philosopher)
        63:
        64:   @eating << philosopher
        65:   philosopher.async.eat
        66: end

    [1] pry(#<Waiter>)>

Then if we enter `philosopher` at the prompt to inspect it, we can see that it
is indeed an instance of `Actor::Proxy` that has a `@target` of a particular
`Philosopher` instance (Popper).

If we `exit` this pry session, we'll quickly be in the next time
`request_to_eat` is called, and this time we can inspect `@eating` and see that
it contains the `Proxy` for Popper while the current `philosopher` is the
`Proxy` for Schopenhauer.

Replicating this exact situation in a test where we can access the values of
`@eating` and `philosohper` at these particular points in the execution is not
straightforward, but pry makes it easier. This merely scratches the surface of
pry's capabilities-- there are many commands pry provides that are powerful
tools for inspecting your code while it's running.

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
