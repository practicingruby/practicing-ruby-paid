Software projects need to evolve over time, but they also need to avoid
collapsing under their own weight. This balancing
act is something that most software developers understand, but it is often 
hard to communicate its importance to non-technical stakeholders and 
managers. Because of this disconnect, projects tend to operate under the
false assumption that projects must stagnate in order to stabilize. 

This fundamental misconception about how to maintain a stable codebase has some
disasterous effects: It causes risk-averse organizations to produce stale 
software that quickly becomes irrelevant, while risk-seeking organizations ship 
buggy code in order to rush features out the door faster than their 
competitors. In either case, the people who depend on the software produced by
these organizations give up something they shouldn't have to.

I have always been interested in this problem, because I feel it is at the 
root of why so many software projects fail. However, my work on Practicing Ruby
has forced me to become much more personally invested in solving it. As someone
attempting to maintain a very high quality experience on a shoestring budget, I
now understand what it is like to look at this problem from a stakeholder's
point of view. In this article, I will share the lessons I've learned from the
work Jordan Byron and I have been doing to maintain Practicing Ruby's web
application.

In particular, I will discuss the techniques that have allowed us to make 
the most out our very limited development time, which is often as little 
as 5-10 hours per week. We didn't invent any of these practices; we picked 
them up mostly by studying what works for other people. However, we've learned
that these ideas are complimentary to one another, and so the net 
benefit to us has been greater than the sum of its parts. In other words,
this article forms a comprehensive recipe for keeping software stable 
as it grows -- without wasting tons of time and money!

### Rule 1: Work incrementally

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

### Rule 2: Review everything

It is no secret that code reviews are useful for driving up code quality and
reducing the number of defects that get introduced into production in the first
place. However, figuring out how to conduct a good review is something that
takes a bit of fine tuning to get right.

We've found through trial and error that code reviews generally go a lot better
if you start by simply walking through how things work at a functional level.
The reviewer attempts to use the new feature while its developer answers any 
questions that come up along the way. Whenever an unanticipated
edge case or inconsistency is found, we immediately file a ticket for it. We
repeat this process until all open questions or unexpected issues have been 
documented.

Unless the feature's developer has specific technical questions for the
reviewer, we don't bother with in-depth reviews of implementation details until
all functional issues have been addressed. This prevents us from spending time
on bikeshed arguments about potential refactorings, or hypothetical sources of
failure at the code level. Doing things this way also reminds us that the
external quality of our system is our highest priority, and that while clean
code makes building a better product easier, it is means, not an end in itself.

Once a feature seems to work as expected in the eyes of both the developer and
the reviewer, the next area we turn our attention to is the tests. It is the
reviewer's responsibility to make sure that the tests cover the issues brought
up during the review, and also generally exercise the feature well enough to
prevent it from silently breaking. Sometimes the reviewer will ask the developer
of the feature to write the tests, other times it is easier for the reviewer to
write the tests themselves rather than trying to explain what is needed. In
either case, the end result of this round of changes is that the feature's
requirements end up getting pinned down a bit more than it might have been 
at the outset. Because many of these tests can be written at the UI level, it is
common to have still not discussed implementation details at this stage of a
review.

By now, the feature is tested well enough, and its functionality has been 
exercised more than a few times. That means that a spot check of its source code 
is in order. Generally speaking, the goal is not to make the code perfect, 
but to identify both low-cost improvements that can be done right away, 
and any serious warning signs of potential problems that may make the 
code hard to maintain or error-prone. We see everything else as 
something that can be dealt with later -- if and when a feature needs to be 
built on top of or modified.

While this may sound like a very rigorous practice, it isn't as daunting as it
seems. Most of the time, we can cycle through all the stages of our review very
quickly, because we usually tend to only look at small bits of functionality at
a time. When working on larger multi-faceted changes, we will often do the
reviews in stages to prevent reviews from dragging on forever.

### Rule 3: Stay alert

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

### Rule 4: Rollback ruthlessly

Working on one incremental improvement at a time makes it easy 
to revert newly released functionality as soon as we find 
out that it is defective. At first, we got into the habit of 
rolling things back to a known stable state because we didn't
know when we'd get around to fixing the bugs we uncovered. Later
on, we discovered that this approach allows us to take
our time and get things right rather than rushing to get quick
fixes out the door.

Disciplined revision control practices are essential for supporting
this kind of workflow. We started out by practicing [Github Flow][gh-flow]
in its original form, and that worked out fairly well for us:

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
commits. As it turns out, this approach is very similar to [Github's more recent
deployment practices][gh-deploy-aug-2012], minus all their fancy robotic
helpers.

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

### Rule 5: Minimize effort

Every time we find a defect in one of our features, we ask ourselves whether
that feature is important enough to us to be worth fixing at all. Properly
fixing even the most simple bugs takes time away from our work on other
improvements, and so we are easily tempted to cut our losses by removing
defective code rather than attempting to fix it. Whether we can get away with
that or not ultimately depends on the situation.

Sometimes, defects are severe enough that they need to be dealt with right away,
and in those cases we [stop the line][autonomation] to give the issue the
attention it deserves. The best example of this we've encountered in recent
times was that we neglected to update our omni-auth version before Github shut
down an old version of their API, and that disabled logins temporarily for all
Practicing Ruby subscribers. We had an emergency fix out within hours, but it
predictably broke some stuff. Over the next couple days, we added fixes for
the edge cases we hadn't considered until the system stabilized again. Because
this wasn't the kind of defect we could easily work around or rollback from, we
were working under pressure, and attempting to work on other things during that
time would have only made matters worse.

At the other extreme, some defects are so trivially easy to fix that it makes
sense to take care of them as soon as you detect them. A few weeks before this
article was published I noticed our broadcast email system was treating our
plain text messages as if they were HTML that needed to be escaped, which caused
some text to be mangled. If you don't count the accompanying test, fixing this
problem was [a one-line change][htmlescape] to our production code. Tiny bugs 
like this are best to fix right away, as it helps keep them from accumulating 
over time.

The vast majority of defects we discover are somewhere between these two
extremes, and figuring out how to deal with them is not nearly as
straightforward. The lesson we've gradually learned over time is that it is
better to assume that a feature can either be cut or simplified and then try to
prove ourselves wrong rather than doing things the other way around. However, we
still forget this rule on occasion, and we inevitably end up paying the price
for it.

Take for example our work on making account cancellation easier for subscribers.
We had assumed that what folks would want is an easy to find link on their
account settings page that would automatically cancel their account with no
further action required on their end. While this assumption is valid on its own,
it lead us down a very deep rabbit hole. In order to make cancellation
*automatic*, we'd need to handle API calls to both Mailchimp and Stripe
(depending on the subscriber's payment provider), and we'd also need to handle
the case where there was no payment provider at all. There were also lots of
other little things to consider, most of which we didn't even think about until
we started implementing the feature. After a few hours of discussion and
development work, we had a partially completed feature which *almost* worked,
but still had some remaining issues with it. Almost immediately after deploying
it to production, we rolled it back and decided it simply wasn't ready yet.

After listening to Jordan and I complain about what a frustrating day we had, my
wife Jia asked us why we hadn't considered simply handling the cancellation process 
manually for the time being. We went on to explain to her that we wanted to make
it so that subscribers didn't have to email us and have a back-and-forth
exchange in order to cancel their accounts, because we felt that would be a
terrible experience for them. It was at that point that she suggested that we
might be able to make it so that every time a customer clicks the "unsubscribe"
link, and email gets sent to us with the information necessary to manually
cancel their account -- a process that takes us only a few seconds to complete
and only happens a few times a week.

Although it took us a little while to let this idea in, we eventually realized
that it was the exact right thing to do, at least as a stopgap measure.
Implementing the semi-automatic process was so much simpler than the fully-automatic one that
we were able to build and ship it in a fraction of the time that we spent
*discussing* the more complicated feature. So rather than fixing the problems
with our very complex code, we replaced it with something more simple and
accepted that our initial efforts were a sunk cost. Even though this may have
temporarily bruised our egos a bit, it was the right thing to do.

Killing code is not an easy thing to do emotionally, but these small sacrifices
go a long way to improving the overall quality of your projects. This is why we
can't just decide whether a bug is worth fixing based on the utility of the
individual feature it effects: we need to think about whether our time would be
better spent working on other things. It is only worth resolving defects 
if the answer to that question is "No!"

### Rule 6: Prevent regressions 

One clear lesson that time has taught us is that bugs which are not covered by
a test inevitably come back. To prevent this from happening, we
try to write UI-level acceptance tests to replicate defects as the first step 
in our bug-fixing process rather than the last.

Adopting this practice was very tedious at first. Even though [Capybara][capybara]
made it easy to simulate browser-based interactions with our application, 
dropping down to that level of abstraction every time we found a new
defect both slowed us down and frustrated us. We eventually realized that we
needed to reduce the friction of writing our tests if we wanted this good habit
to stick. To do so, we started to experiment with some ideas I had hinted at
back in [Issue 4.12.1][pr-4.12.1]: application-specific helper objects for 
end-to-end testing. We eventually ended up with tests that look something like
the following example:

```ruby
class ProfileTest < ActionDispatch::IntegrationTest
  test "contact email is validated" do
    simulate_user do
      register(Support::SimulatedUser.default)
      edit_profile(:email => "jordan byron at gmail dot com")
    end

    assert_content "Contact email is invalid"
  end

  # ...
end
```

If you strip away the syntactic sugar that the `simulate_user` method provides,
you'll find that this is what is really going on under the hood:

```ruby
test "contact email is validated" do
  user = Support::SimulatedUser.new(self)

  user.register(Support::SimulatedUser.default)
  user.edit_profile(:email => "jordan byron at gmail dot com")

  assert_content "Contact email is invalid"
end
```

Even without reading the [implementation of Support::SimulatedUser][simulated-user],
you have probably already guessed that it is a simple wrapper around Capybara's
functionality that provides application-specific helpers. This object provides
us with two main benefits: reduced duplication in our tests and a vocabulary
that matches our application's domain rather than its delivery mechanism. The
latter feature is what reduces the pain of assembling tests to go along 
with our bug reports.

Let's take a moment to consider the broader context of how the this email
validation test came into existence in the first place. Like many changes we
make to Practicing Ruby, this particular one was triggered by an exception
report which revealed to us that we had not been sanity checking email 
addresses before updating them. This problem was causing a 500 error to be 
raised rather than failing gracefully with a useful error message, which pretty
much guaranteed a miserable experience for anyone who encountered it. The steps
to reproduce this issue from scratch are roughly as follows:

1. The user registers for Practicing Ruby
1. The user attempts to edit their profile with a badly formatted email address
1. The user SHOULD see a message telling them their email is invalid, but
instead encounters a 500 error and a generic "We're sorry, something went wrong"
message.

If you compare these steps to the ones that are covered by the test, you'll see
they are almost identical to one another. While the verbal description is
something that may be easier to read for non-programmers, the tests communicate
the same idea at nearly the same level of abstraction and clarity to anyone who
knows how to write Ruby code. Because of this, it isn't nearly as easy for us to
come up with a valid excuse for not writing a test or putting it off until
later.

Of course, old habits die hard, and occasionally we still cut corners when
trying to fix bugs. Every time we encounter an interaction that our
`SimulatedUser` has not yet been programmed to handle, we experience the same
friction that makes it frustrating to write acceptance tests in the first place.
When that happens, it's tempting to put things off or to cobble together a test
in haste that verifies the behavior, but in a sloppy way that doesn't make
future tests easier to write. The lesson here is simple: even the most
disciplined processes can easily break down when life gets too busy or too
stressful.

To mitigate these issues, we rely once again on the same practice which allows 
us to let fewer bugs slip into production in the first place: active peer
review. Whenever one of us fixes a bug, the other one reviews it for quality and
completeness. This process puts a bit of peer pressure on both of us to not be sloppy
about our bug fixes, and also helps us catch issues that would otherwise hide
away in our individual blind spots. This practice reduces the amount of 
repeated attempts to properly fix a bug, and also reduces the likelihood that
defects will resurface. Any time not spent hunting down
old bugs or trying to pin down new ones is time we can spend on things that
actually make our software more valuable, and so we don't mind investing a little
more time up front to help make that happen.

### Reflections

Do we follow all of these practices completely and consistently without fail? Of
course not! But we do try to follow them most of the time, and have
found that they work best when taken together as a group. That is not to say
that removing or changing any one ingredient would spoil the soup, but only that
it is hard for us to guess what their effects would be like in isolation.

It's important to point out that we adopted these ideas organically rather
than carefully designing a process for ourselves to rigidly follow. This article
is more of a description of how we viewed things at the time this article was
published than it is a prescription for how people ought to approach all
projects, all the time. We've found that it works best to maintain a consistent
broad-based goal (ours is to make the best possible user experience with the
least effort), and to continuously tweak your processes as needed to meet that
goal, rather than the other way around. Maintaining a bit of fluidity about the
way you approach processes are essential, because rigid processes can kill a
project even faster than rigid code can.

In the end, much of this is very subjective and context dependent. I've shared
what works for us in the hopes that it'll be helpful to you, but I want to
hear about your own experiences as well. Because our own process is
nothing more than an amalgamation of good ideas that other people have come up
with, I'd love to hear what you think might be worth adding to our recipe.

[mendicant]: http://mendicantuniversity.org
[travis]: http://about.travis-ci.org/docs/user/getting-started/
[lean]: http://en.wikipedia.org/wiki/Lean_software_development 
[exception-notification]: https://github.com/smartinez87/exception_notification
[gh-flow]: http://scottchacon.com/2011/08/31/github-flow.html
[capybara]: https://github.com/jnicklas/capybara
[pr-4.12.1]: http://practicingruby.com/articles/66
[simulated-user]: https://github.com/elm-city-craftworks/practicing-ruby-web/blob/f00f89b0a547829aea4ced523a3d23a136f1a6a7/test/support/simulated_user.rb
[autonomation]: http://en.wikipedia.org/wiki/Autonomation
[htmlescape]: https://github.com/elm-city-craftworks/practicing-ruby-web/commit/223ca92a0b769713ce3c2137de76a8f34f06647e
[gh-deploy-aug-2012]: https://github.com/blog/1241-deploying-at-github
