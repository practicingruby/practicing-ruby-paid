The easiest way to stabilize a software project is to stop
changing its requirements. When no new functionality gets added to a system, and no existing
functionality is modified, the number of defects will gradually decline over
time as long as the code is actively maintained. However, because we live in a
world in which continuous improvement is now the norm, the concept of
permanently freezing a codebase seems like an archaic practice.

The cost of our modern agility is that stability is a much harder problem to
solve when everything is constantly changing under foot. If the demand for new 
features come in faster than it takes for programmers to truly understand the
existing functionality of the systems they are working on, defects 
inevitably accumulate. Over time, buggy code gets layered on top of other buggy
code, and that causes systems to degrade even faster. Sooner or later, a feature
freeze happens out of necessity, and talks of "the big rewrite" become
inevitable. Depending on the context, this unplanned stagnation
may end up being just as limiting as it would have been to ship a fixed-scope
project.

Most developers understand both the value of allowing systems to evolve over time as
well as the essential role that stability plays in creating a high quality user
experience. The problem is that we are often under external pressure to conform to
processes which do not strike a reasonable balance between these two interests,
leading to a false choice between stagnation and instability. If that tension
did not exist, what would we do differently?

Over the last couple years, Jordan Byron and I have been trying to answer that
question for ourselves, at first with our work on [Mendicant
University][mendicant], and now with Practicing Ruby. In this article, I will
share the guidelines we have developed for minimizing the impact of defects in
our code without giving up our ability to grow and change our software whenever
we need to.


- https://github.com/elm-city-craftworks/practicing-ruby-web/issues/51
- https://github.com/elm-city-craftworks/practicing-ruby-web/issues/73

At least some commits 40 out of 52 weeks

* Added syntax highlighting
* Overhauled our comments system to include mention support, emoji, live
previews, etc.
* Added email notifications for various things
* Added collections / volumes support
* Added caching
* Added a bunch of Mailchimp workarounds
* Completely redesigned the site
* Overhauling email delivery / payment processing

![Commit frequency by week](http://i.imgur.com/H8Aql.png)

---

### Lean development practices

Because we only have a few hours of development time available each week, we
need to work very efficiently. We've found that many of the [Lean Software 
Development][lean] practices work well for us, and so we've
been gradually adopting them over time.

One of the biggest influences that the Lean mindset has had on us is that we now
view all work-in-progress code as a form of waste. This way of looking at things 
has caused us to eschew iteration planning in favor of shipping a single
improvement or fix at a time. This workflow may seem a bit unrealistic at 
first glance, but with some practice it is possible to break very 
complicated features into tiny bite-sized chunks. We now work this way by
habit, but our comment system was the first thing we approached in 
this fashion.

When we first implemented comments, we had Markdown support, but not much else. 
Later on, we layered in various improvements one by one, including syntax 
highlighting, email notifications, Twitter-style mentions, and Emoji support. 
With so little development time available each week, it would have taken 
months to ship our discussion system if we attempted to build it all at once.
With that in mind, our adoption of a Lean-inspired deployment strategy was not just a
workflow optimization; it was an absolute necessity. Later on, we also came to 
realize that this constraint was a source of strength rather than weakness for
us. Here's why:

*By developing features incrementally, there
are less moving parts to integrate on each deploy. This also means that there
are fewer opportunities for defects to be introduced during development.
When new bits of functionality do fail, finding the root
cause of the problem is usually easy, and even when it isn't, rolling the system
back to a working state is much less traumatic. These things combined result in
a greatly reduced day-to-day maintenance cost, and that means more time can
be spent on value-producing work.*

As you read through the rest of the guidelines in this article, you'll find that
while they are useful on their own, they are made much more effective by this
subtle shift in the way we ship things.

### Peer review / demonstrations

**~~~~~~~~~~~~~~~~~~WORK IN PROGRESS~~~~~~~~~~~~~~~~~~~**

We demonstrate all but the most trivial changes to one another, at both the
functional and the code level. We *start* with the actual experience of using
the features, and only bother with code reviews once we answer any questions
that arise at the functional level.

This approach inevitably reveals edge cases and misconceptions, which we
document with tests. We tend to start this process as early as possible, opening
a pull request when we have even the most minimal bit of real functionality.
Rather than having the person developing the feature think of all of what can go
wrong, we push a big chunk of that responsibility on the reviewer. This is very
effective, because similar to writing prose, there is a big difference between
"creative mode" and "editing mode", and this process reflects that.

This process of peer review shakes out MANY defects before we ever roll
something into production, and it makes it harder for us to cut corners.

### Early warning system

When something does go wrong, we want to know about it as soon as possible.
We rely on many different ways of detecting problems, and we automate as much as
we can.

Our first line of defense is our continuous integration system. 
We use [Travis CI][travis], but for our purposes pretty much any CI tool would
work. Travis does a great job of catching environmental issues for us: things
like dependency issues, configuration problems, and other subtle things that
would be hard to notice in development. It also helps protect us from
ourselves: Even if we forget to run the entire test suite before pushing a set
of changes, Travis never forgets, and will complain loudly if we've broken the
build. Most of the mistakes that Travis can detect are quite trivial, but
catching them before they make it to production helps us keep our service
stable.

For the bugs that Travis can't catch (i.e. most of them), we rely on
the [Exception Notifier][exception-notification] plugin for Rails. While most
notification systems would probably do the trick for us, we like that Exception
Notifier is email-based; it fits into our existing workflow nicely. The default
template for error reports works great for us, because it provides everything
you tend to get from debugging output during development: session data,
environment information, the complete request, and a stack trace. If we start to
notice exception reports roll in soon after we've pushed a change to the system, this
information is usually all we need in order to find out what caused the problem.

Whenever we're working on features that are part of the critical path of our
application, we tend to use the UNIX `tail -f` command to watch our production 
logs in real time. We also occasionally write ad-hoc reports that give us 
insight into how our system is working. For example, we built the following 
report to keep an eye on account statuses when we rolled out a partial replacement 
for our registration system. We wanted to make sure it was possible for folks to
successfully make it to the 'payment pending' status, and the report showed
us that it was:

![Account status report](http://i.imgur.com/NOI0A.png)

Our proactive approach to error detection makes it so that we can rely less on
bug reports from our subscribers, and more on automated reports and alerts. This
works fairly well most of the time, and we even occasionally send messages
to people who were affected by bugs in our system letting them know that we fixed 
their problem before they attempt to contact us. That said, bug reports from
humans rather than machines can provide a lot of useful context, so we 
display our email address prominently on our error pages in the application.
Any email sent to that address makes its to both me and Jordan, so
that we can deal with them promptly.

While a lot more can be said about efficient error detection, we have lots of
other topics to discuss in this article and should try to maintain an even pace.
But before we move on, here are a few things to think about when applying these
ideas in your own applications:

*The main reason to automate error detection as much as possible is because the
people who use your application should not be treated like unpaid QA testers.
The need for an active conversation with your users every time something goes
wrong with a system is a sign that you have poor visibility into its failures,
and ought to fix that. However, be aware of the fact that every automated error
detection system  requires some fine tuning to get
right. If your system is exposed to internet traffic of
any kind, you can expect all sorts of weird stuff to happen, including bots who
attempt to do things to your application that humans would never do. Fixing or 
filtering out these kinds of issues can be time consuming, but is essential if
you want your warning system to not become a potentially dangerous and noisy
mess.* 

I'd love to discuss this topic more, so please ask me some questions 
or share your thoughts once you've finished reading this article if you're
interested in this kind of thing.

### Ruthless rollbacks

Working on one incremental improvement at a time makes it easy 
to revert newly released functionality as soon as we find 
out that it is defective. At first, we got into the habit of 
rolling things back to a known stable state because we didn't
know when we'd get around to fixing the bugs we uncovered. Later
on, we discovered that this approach allows us to take
our time and get things right rather than rushing to get quick
fixes out the door.

Disciplined revision control practices are essential for supporting
this kind of workflow. We started out by practicing [Github Flow][gh-flow],
and that worked out fairly well for us:

> 1. Anything in the master branch is deployable
> 2. To work on something new, create a descriptively named branch off of master (ie: new-oauth2-scopes)
> 3. Commit to that branch locally and regularly push your work to the same named branch on the server
> 4. When you need feedback or help, or you think the branch is ready for merging, open a pull request
> 5. After someone else has reviewed and signed off on the feature, you can merge it into master
> 6. Once it is merged and pushed to ‘master’, you can and should deploy immediately

Somewhere down the line, we made a small tweak to the formula by deploying
directly from our feature branches before merging them into master. This
approach allows every improvement we ship to get some live testing time in
production before it gets merged into master, greatly increasing the stability
of our mainline code. Whenever trouble strikes, we deploy from our master branch
temporarily, which executes a rollback without explicitly reverting any
commits.

While this process significantly reduces the amount of defects on our master branch,
we do occasionally come across failures that are in old code rather than in our
latest work. When that happens, we tend to fix the issues directly on master
(merging a branch if it's a complicated change), verify that they work as
expected in production, and then attempt to merge those changes into any active
feature branches. Most of the time, these merges can be cleanly applied, and so
it doesn't interrupt our work on new improvements all that much.

When we do see a lot of complicated merges going on, or repeated rollbacks from
a feature branch, we take it as a sign that we need to slow down and take a
closer look at things. If we're having to fix lots of bugs on our master branch,
it is a sign that we may have merged features into it prematurely, or that the
integration points in our system have become too brittle and need some 
refactoring. Alternatively, if we've attempted to deploy a new feature into
production several times and keep finding new things wrong with it, it may be a
sign that the feature isn't very well thought out and that we need to go back to
the drawing board. While neither of these situations are pleasant to deal with,
the constraints we place on the way we deploy things help us find and fix these
problems before the spiral out of control.

It's also worth noting that the process of falling back to master whenever
something goes wrong is a good default, but it is not a one-size-fits-all 
solution. Sometimes we botch a deploy in a very trivial way, and in those 
cases, Capistrano's built in `deploy:rollback` command is useful for 
simply undoing a deploy and then trying again once a fix is ready. At the 
other extreme, we occasionally introduce changes that would be tricky to 
revert without complications. In those cases, we do the best we can to 
temporarily disable features or degrade them gracefully at a UI level,
so that the defects we spot don't have a widespread effect.

This practice does indeed feel a bit ruthless at times, and it definitely takes
some getting used to. However, by treating rollbacks as a perfectly acceptable
response to a newly discovered defect rather than an embarrassing failure, a
totally different set of priorities are established that help keep things in a
constant state of health. 

### Fixes before features

**~~~~~~~~~~~~~~~~~~WORK IN PROGRESS~~~~~~~~~~~~~~~~~~~**

Because we work on a single feature at a time, we don't need to make the same
compromises between bug fixes and new feature work that often arise in
iteration or release planning.

Generally speaking, whenever we have to disable a feature temporarily because it
has a bug in it, we have to make the decision of whether to fix that issue as
soon as possible or to remove the feature and reimplement it later. Most of the
time, we choose to stop work temporarily on new feature work and attempt to
investigate and fix bugs in existing features quickly after detecting them. This
allows us to sort things out while they're fresh in our minds (we also may even
have someone who experienced the problem to help us test our fixes!)

However, if we find a defect hard to fix, or if we don't understand how to fix
it, we think about what the cost of fixing it will be compared to the cost of
killing the feature off. Doing the investigation early helps us make this
decision before the issue becomes stale.

This policy encourages us to avoid allowing buggy code to linger, and it also
makes it so that we put a bit more effort into avoiding getting into this
situation in the first place.

### Bugs are replicated via tests

**~~~~~~~~~~~~~~~~~~WORK IN PROGRESS~~~~~~~~~~~~~~~~~~~**

We do peer reviews on non-trivial bug fixes similar to how we review feature
work: demonstration at the functional level and inspection at the code level.

I don't do a lot of our development work, but I fairly frequently write extra
tests to document our fixes, and when I do prepare my own fixes, Jordan does the
same for me. The basic idea is that our "What if?" and "How does?" kind of
questions get documented in tests, not just answered in conversation or by
manual inspection.

We often start at the acceptance testing level, attempting to create a test that
comes as close to possible to reproducing the failure at the level it was
actually experienced. We've been improving our acceptance test helpers to make
this easier, as it can be pretty time consuming.

Because bug reports often reveal other potential sources of failure, we will
often write some additional tests around those as well, starting again with
acceptance tests, and layering in unit tests as necessary for non-trivial
business logic errors.

### NOTES TO INTEGRATE

- No releases / iterations
- Master kept constantly deployable, deploy one new feature at a time whenever
  we're ready. (Slow form of continuous deployment)
- Peer review on every non-trivial change: Demo at functional and code level.
- We don't do rigorous TDD, but we clarify any assumptions or prove the answer
  to any questions via tests: if we have a doubt about a edge case, we write a
  test for it.
- The demo process catches many bugs before the code ever hits production.
- Immune system: Continuous integration, exception notifier, logs, user reports,
  bugs we find on our own while using the system.
- Exception notifier is one of our most valuable resources, but we needed to do
  a lot of work to make it usable: crawlers like to break stuff! If you are
  getting mostly noise for error reports then you will be more likely to
  ignore them.
- Rollback immediately when a bug is detected unless it has a very minor impact on
  very few people.  (cap rollback or branch swapping)
- When rollback isn't feasible, hide the feature or work around the problem at
  the UI level until the issue is resolved.
- To make this easier, we will deploy from topic branches until a feature seems
  stable enough to merge into master. (Regularly merging master into those
  branches to keep them fresh)
- If a bug is detected in an old changeset, the fix is applied on master, and
  then merged into the topic branch. If there are conflicts on the topic branch,
  we revert to master until those can be resolved.
- Every time we encounter a defect which affects quality of service, feature
  work is halted until that issue is fixed, or the affected code is removed.
- We review each other's fixes and put peer pressure on tests: this is the one
  area where we're very strict about testing. I don't do much development
  myself, but I will definitely write tests to verify any suspicions I have
  about the suitability of a fix. (Link to some real commit messages)

COMMENT ON VELOCITY

- This process would work great for a side project or open source web app, or in
  any environment in which moving slow is OK and you have lots of trust with the
  stakeholders. With some modifications, it could probably be adopted to larger
  projects with faster pace, too.

[mendicant]: http://mendicantuniversity.org
[travis]: http://about.travis-ci.org/docs/user/getting-started/
[lean]: http://en.wikipedia.org/wiki/Lean_software_development 
[exception-notification]: https://github.com/smartinez87/exception_notification
[gh-flow]: http://scottchacon.com/2011/08/31/github-flow.html
