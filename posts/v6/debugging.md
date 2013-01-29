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
and despair. The use of scientific techniques, however, can provide systematic
ways to get out of any sticky situation.

## Narrow down the problem

* Infinite search space of interacting components
* Use scientific method: make a hypothesis, design an experiment to confirm or deny, do it, analyze results, repeat.
* Top-down vs bottom up, same goal: eliminate any moving pieces that are not contributing to the problem

### Practice

For a talk on debugging that I gave with Jake Goulding at Codemash 2013, we
did some live debugging on a Rails application. I created a Rails application
with a particular bug manifestation, but every time we practiced I made the
bug implementation a little trickier to find. [I've shared the code and the
different bugs on GitHub](https://github.com/carols10cents/narrow_down) as
potential practice for others. There are more details in the README; please
let me know if you try this out and if you found the practice useful!

## Read Stack Traces

Stack traces are ugly. They typically present as a wall of text in your
terminal when you aren't expecting them. When pairing, I've often seen people
ignore stack traces entirely and just start changing the code. But stack
traces do have valuable information in them, and learning to pick out the
useful parts of the stack trace can save you a lot of time in trying to narrow
down the problem.

The two most valuable pieces of information are the resulting error message
(which is usually shown at the beginning of the stack trace in Ruby) and the
last line of your code that was involved (which is usually somewhere in the
middle). The error message will tell you *what* went wrong, and the last line
of your code will tell you *where* the problem is coming from. For example:

<!--
Insert rstat.us stack trace here
 -->

There are some exceptions, such as the dreaded "syntax error, unexpected $end,
expecting keyword_end" error, which will usually point to the end of one of
your files. It actually means you're missing an `end` somewhere in that file.
If you're not sure what an error is telling you, often a search for ruby and
the error message will point you in the right direction.

### Practice

<!--
Insert a different rstat.us stack trace and encourage someone to send a pull request to fix it??? Too self-serving?? ;)
 -->


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
some code. Much like irb, this lets you try out ideas and hypotheses quickly.

For example, if we have this code:

<!-- Need to flesh this out into something realistic -->
    class Whatever
      def something
        binding.pry
      end
    end

and run it using `ruby whatever.rb`, this is what you'll see when the code
hits the `binding.pry`:

### Practice

<!--
Get the rstat.us codebase, insert a binding.pry in a location, look at these
things and see these effects
 -->

## Lean on tests

Whenever you need to fix a bug, you're writing a test first, right? This
serves multiple purposes: it gives you a convenient way to reproduce the issue
while you're experimenting, and if added to your test suite, it will help
prevent regressions of this bug happening in this way again.

But not all tests need to be added to your test suite. While debugging, it can
be a useful way to record your discoveries. If you are only able to write an
end-to-end integration test that reproduces the bug, you

Some tests don't make sense to add to a test suite, especially negative
examples such as "it should not crash when given special characters". The
situation is just too specific to happen exactly that way again. A better way
to add such a test

<!--
There are some examples in the rstat.us test suite that could be improved in this way
-->

### Practice

<!--
Find some of your tests that could be rewritten? Write tests for a bug in
the narrow_down codebase?
-->

Even though sometimes it seems like software has a mind of its own, computers
only do what a human has told them to do at some point. You **can** figure out
why a bug is happening by using the scientific method to narrow down where the
problem is happening. You **can** learn to pick out the useful parts of stack
traces. You **can** use debuggers to experiment with what your code is
actually doing as it runs. And you **can** write tests that help you while
debugging and then turn them into useful regression tests. Go figure out some
bugs! <3

## References

* [Debug it!](http://pragprog.com/book/pbdp/debug-it) by Paul Butcher
* [Railscast on Pry](http://railscasts.com/episodes/280-pry-with-rails)