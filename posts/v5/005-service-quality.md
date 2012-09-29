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

### Pipeline production model

We tend to eschew iterations and large scale release planning in favor of
shipping a single atomic feature at a time whenever possible. We started working
this way because of our severely limited resources (we only have about 10 hours 
a week of development time available on average), but we later found that
shipping individual features made it much easier to spot and resolve defects in
newly developed code.

(Describe payment changes here)
(Note that this isn't always feasible in production, but can be 
emulated in development -- e.g. site redesign)

### Peer review / demonstrations

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

### Rapid error detection

We rely on many different ways of detecting problems, and we automate as much as
we can.

* Travis: Good for catching environmental issues: Did we forget to update a
configuration file, is a complicated dependency not set up right, etc? Did
someone simply forget to run the entire test suite before pushing? (Autotest /
spin+kicker example)

* Exception notifier: Good for catching unexpected failures and providing the
necessary context for reproducing them.  However, you need to do a lot of fine
tuning to get these to be useful: i.e. fix any trivial bugs that get triggered by
bots. Automated error reports are only good if they are almost ALL actionable,
otherwise you run into a boy called wolf effect. BE CAREFUL ABOUT TIGHT FAILURE
LOOPS, THEY SEND EMAILS LIKE CRAZY!

* Reports from subscribers: Useful for catching soft failures (i.e ones that 
aren't causing exceptions), or for providing additional context about hard failures.

* Logs: We watch them when we've rolled out a major change, and we watch them
whenever we send a broadcast email to make sure that the requests coming back
look sane. We also will search our logs when we want to investigate problems
that are hard to diagnose via exception notifier (i.e. workflow issues)

* Dogfooding: Jordan is constantly manually testing the app while developing,
as that's how we test usability. We are able to sync most of our data from
production into development to give a realistic environment. I am also
constantly using the application while writing articles, responding to comments,
etc, so I am often the first to run into problems before others experience them.

### Revert ruthlessly

Working in terms of individual features makes it easy to revert newly released
functionality as soon as we find it is defective. This is usually the first step
for us in filing a bug report. To make this even easier, we often deploy from
feature branches (which are kept in sync with master) before merging features
into master, which makes it easy for us to cut back to stable system temporarily
while fixes are being worked on. That combined with cap rollback go a long way.

This is another one of those things that we started doing from having very
limited resources: we would learn about a bug and realize we may not get to it
for a few days, but didn't want to have our quality of service degrade while we
waited to fix things. Later on, we realized that this approach greatly reduced
the temptation to put together hackish "quick fixes", which can introduce new
bugs while fixing old ones.

When we fix issues that we found in older code rather than the current feature
under development, we revert it in master and then merge it into any active feature
branches if necessary. If this creates conflicts, we deploy master until we can
sort out how to get things reverted on the feature branch.

On rare occasions, reverting would be too traumatic or complicated. When that
happens, we will implement workarounds or disable features at the UI level so
that the impact on subscribers is minimal.

### Fixes before features

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

### Replicate via tests

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
