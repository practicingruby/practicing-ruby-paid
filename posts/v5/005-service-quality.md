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
experience, we are often under external pressure to conform to
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
(summarize major changes / improvements)

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
