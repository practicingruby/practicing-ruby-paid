![](http://i.imgur.com/JqYK6TZ.jpg)

Software is similar to an iceberg: there is far more mass below the waterline than there appears to be at the surface level. As programmers, we're aware of this fact -- but we still deeply underestimate the challenges involved in making changes to the systems we maintain. 

For a particular project, the only way to reliably survey the depth and complexity of the landscape is to dive into the frigid water and see it with your own eyes. However, gaining knowledge this way is a slow and arduous process that hinders your ability to notice general patterns that aren't project-specific. For this reason, trading stories with others about your explorations beneath the waterline can be extremely helpful. 

To illustrate both the iceberg effect and the benefits of sharing stories about our experiences, this article walks you through a set of changes to practicingruby.com that ended up being much more work than I expected them to be. Fair warning: the plot may be painful at times, but it should at least leave you with some useful lessons to apply in your own projects.

## Contributors to the iceberg effect

* Framework issues (Rails behaviors)
* Dependency compatability (outdated)
* Lack of knowledge
* Lack of informed decision making due to "organic" or "need based" design
* Testing complexity, testing toolchain complexity


> Special thanks goes to Jordan Byron (the maintainer of practicingruby.com) for collaborating with me on this article, and for helping Practicing Ruby run smoothly over the years.

http://www.joelonsoftware.com/articles/fog0000000356.html


*HOW COMPLEX IS A GIVEN CHANGE? WE HAVE NO IDEA UNTIL WE FIND THE BOTTOM!*

**TODO: Rewrite intended changes as before/after (maybe even using a diff or table view)**

Intended changes:

1. Unify URL scheme between "share links" and "internal links"
2. Dynamically determine whether to use shared view or internal view depending
on whether the visitor is logged in.
3. Make URLs less opaque through the use of slugs
4. Do all of this without breaking old links and behaviors

```
/articles/101                     => /articles/data-exploration-techniques?u=fadafada10
/articles/shared/lkjlkjgadskjsgda => /articles/data-exploration-techniques?u=fadafada10
```

Things worked on (in order):

> TODO: SPLIT PULL REQUESTS INTO DISCUSSION / "Files Changed" DIFF
> Should we include diffs inline or code samples where relevant, or just link?

# READ ALL PULL REQUESTS CAREFULLY AND ALSO THINK BACK ABOUT CHALLENGES, NOTES BELOW ARE JUST "TOP OF THE HEAD" SKETCHES.

## PRELIMINARIES

**Hide robobar -- [Pull Request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/125/files)**

We had two ways to generate share links, but we want to move towards "zero". We killed Robobar, 
because it was obviously an unfinished work.

However, extraction would be hard, so we hid it instead. Had to delete some tests
to get things back to green, but they were areas that will go away.

**Make logins explicit -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/issues/142)**

This is a problem that would largely go away once the new system was in place. However, there 
would still be old links lingering around, and this problem was happening regularly
enough to be annoying.

Relatively simple fix (albeit with one hiccup that caused us to pull it from
 deployment temporarily) and it solved this particular problem a month
 before we were able to ship the more general solution.
 
 When we found a bug, it hinted at a hole in our test suite which I filled.
 
 **(Diversion?) Remove capybara-webkit -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/151)**
 
 Started down this road because I was worried that my tests not stopping was a sign of a broken environment (later reproduced elsewhere and facepalmed). Blew out my Ruby and its gems, and as a result couldn't recompile capybara-webkit with our weird mix of dependencies.
 
 Lost a day to capybara-webkit dependency issues, and then some
 more to writing lower level payment tests. 
 
 > Unsure whether to mention these details as an aside, discuss in detail, or omit entirely. Probably a 1-2 sentence callout is best.

** (Diversion?) Add subscription tests -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/154)**

See above. Is this where I added an Outbox object? If so, maybe discuss it a little or link to it.

## FUNCTIONAL IMPROVEMENTS

**Adding slugs -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/155/files)**

Relatively painless change that we were able to deploy same day as we developed it.
Adding all the slugs took much longer than that, and we didn't want to break /articles/id,
but it had a partial benefit right away.

**Adding user tokens -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/158)**

This was one of those requests where 80% of the time was spent on the first 80% of the problem, and the other 80% of the time was spent on the remaining 20%.

We got this shipped into production quickly (and rightly so, because it was only a useless parameter at that time, meant to allow us to make sure it ended up in all the right places), but then quickly realized the difficulty of writing this code in a DRY fashion.

Eventually settled on adding a path helper override (article_path, article_url) which delegates to a low level object (ArticleLink). Where we were confident we'd have our ApplicationHelper and settle on its default behavior, we used the override, otherwise we explicitly make calls to ArticleLink.

We had to dig way deeper into Rails core behavior than I wanted to in this code (to_params, Rails.app.routes.url_helpers, Capybara, assert_url_has_param in test helper, etc). But we decided to do the best we could, and to ship with warts and all.

Somewhat ambitiously added some (wrong) code for conversation tokenizing here too.

**Make broadcast mailer send individual emails + added mustache -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/162)**

Here we were bit by another Rails core oddity: The way we were using ActionMailer was wrong, and so ActionMailer::Base.deliveries was delivering corrupt results. This lead to a very annoying debugging session. (If you reproduce, check object_id out of curiousity).

This work also left us looking at some ugliness in our tests which we couldn't deal with at the moment, but exposed issues to return to later.

By the end of it, we had mustache URL expansion {{article}}slug{{/article}} but not tokens.

Why add mustache here instead of doing it in a separate pull request? Because originally this was supposed to be a "tokenize broadcast emails" pull request, before we ran into slowness problems.

In order to test our assumptions about speed, we ran a test in production with our queue turned off, so we could check how fast mail was being queued up. We used an exaggerated test (2000 recipients) and that was umm... far too slow. With the current number of recipients (~400) it is fast enough for an internal tool that only I use, but still extremely slow (10-20s, and risks failure on timeout).

We attempted to shoehorn in a call to DelayedJob, but that dragged us back down another rabbit hole that we put off before halting active development on the app... which we need to solve by upgrading to Ruby 2. But for us, that pretty much means a server upgrade.

So we accepted the slowness temporarily while Jordan put the server upgrade on his TODO list, and broke those queueing commits off onto their own pull request with the hopes of applying them before we published this article.

**Diversion? Refactor simulated user to fluent-style API -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/163)**

Can't remember if there was a specific problem to be solved here or if it was just annoying me.

> NOTE: May be cut or summarized as an aside if it doesn't fit the storyline.
  But it's a nice example of the "add new functionality" -> "change callers to use new 
  functionality", -> "remove old functionality (flushing out with raise)" cycle.
  Also a good bonus point on Fluent vs. Instance-eval APIs. (discuss tradeoffs?)
  
**Diversion? Comment anchoring -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/169)**

This is a bug that we vaguely were aware of before, but became more noticeable during testing.
(Also, the login button on the shared page).

We prioritize bugs over feature work (even in these circumstances) so I started on a fix for this and learned that anchors are never submitted to the server (took some digging, due to my ignorance). The way I solved this turned out to be *incompatible* with the other changes I wanted to make though... so this was deployed temporarily and later stalled as I worked on token integration.
  
(closed without merging)

**Share by user Token -- FIXME**

**Tokenized Emails (really just boradcasts -- FIXME**

**New Server!! -- FIXME**

**Delayed broadcast mailer -- FIXME**

## REMAINING ISSUES:

* Overhaul sharing UI and add documentation similar to Ramen's
* Add tokenized comment emails (depends on our new server)
* See board for rest.
  
  
## CLOSING THOUGHTS

* Lots of old bad decisions (or non-decisions really) caught us... something easy to
happen on a side project, or on a limited budget / slow moving project. Even though 
PR is my main job, pr.com is very much a side project for Jordan and I.

* Lack of familiarity with the framework, and lack of currentness in my
experience bit me in many places. Even if I understood our current code,
those issues got in the way of changing it.

* Was it worth it? For us, yes. We're not on a fixed budget or timeline,
and I got to write this article. If I was billing $XXX/hr, I'm not sure
if I'd work on this without wondering *what else* might be lower hanging fruit.

# ------------------------------------------------------------------------------


--- The stories we tell ourselves before we break ground on work, and long after
the work was completed are not even close to giving a clear picture of what
actually happened. This article could expose some of the day-to-day difficulties
of working w. legacy code

--- consider flow-of-consciousness diary style that tells the story of migrating
from existing article URL scheme / sharing scheme to current, talking about
challenges and pitfalls along the way. Underlying point: Changing an existing
system is a lot more challenging than greenfield work, because of all the
stuff below the water line. :-)

Working effectively with legacy code? PR contains a mixture of old bad code from
before we took a quality focus, and better code that wasn't quite finished
before we took a break. 

--- Before and after coverage values!

**Fill in earlier steps here (hiding robobar (why hide instead of kill?), and
maybe explicit logins (what is the problem here?)**

**User tokens**:

Start with URL design

(ramen music inspired, but using params instead of /route/token)

https://practicingruby.com/articles/exploratory-data-analysis?u=p1e02d30558

Had to figure out how to test URL params in Capybara

**Email templating**:

Debate between rolling my own and using a library

>> Mustache.render("Check out the article here:\n{{#article-url}}a-path-to-nowhere{{/article-url}}", "article-url" => ->(e) { articles[e]})
=> "Check out the article here:\nhttps://practicingruby.com/articles/101?u=kdsljsaldgjhgkdljsadgkl"

**Email unbatching**:

- Discuss testing challenges / misuse of Rails

- Discuss delayed job, and how we tested in development by creating thousands of
  users and realized it's definitely slow.

- Talk about how we ran into problems with DelayedJob due to 1.9.2 and
  temporarily deployed the slow code.

- Talk about how we ran into Ruby 1.9.2 problems w. capistrano upgrades right
before starting on this feature, and maybe other times earlier too.

**Fluent API for simulated user**:

http://en.wikipedia.org/wiki/Fluent_interface

Add new functionality, fix interface conflicts (confirm email),
then modify tests to use new functionality. 
Remove old functionality last. (use exception to flush them out... particularly
because blocks could be silently ignored)

```
EditArticleTest
    ERROR (1:00:21.864) can edit articles with slugs
          Block interface has been removed. Make direct method calls instead
        @ test/support/integration.rb:80:in `simulated_user'
          test/integration/edit_article_test.rb:5:in `block in <class:EditArticleTest>'
          /home/gregory/.gem/ruby/1.9.2/gems/activesupport-3.2.13/lib/active_support/callbacks.rb:462:in `_run__1426996139241528895__setup__3843733857777541682__callbacks'
          /home/gregory/.gem/ruby/1.9.2/gems/activesupport-3.2.13/lib/active_support/callbacks.rb:405:in `__run_callback'
          /home/gregory/.gem/ruby/1.9.2/gems/activesupport-3.2.13/lib/active_support/callbacks.rb:385:in `_run_setup_callbacks'
          /home/gregory/.gem/ruby/1.9.2/gems/activesupport-3.2.13/lib/active_support/callbacks.rb:81:in `run_callbacks'
          /home/gregory/.gem/ruby/1.9.2/gems/activesupport-3.2.13/lib/active_support/testing/setup_and_teardown.rb:35:in `run'

    ERROR (1:00:25.176) can edit articles without slugs
          Block interface has been removed. Make direct method calls instead
        @ test/support/integration.rb:80:in `simulated_user'
          test/integration/edit_article_test.rb:5:in `block in <class:EditArticleTest>'
          /home/gregory/.gem/ruby/1.9.2/gems/activesupport-3.2.13/lib/active_support/callbacks.rb:462:in `_run__1426996139241528895__setup__3843733857777541682__callbacks'
          /home/gregory/.gem/ruby/1.9.2/gems/activesupport-3.2.13/lib/active_support/callbacks.rb:405:in `__run_callback'
          /home/gregory/.gem/ruby/1.9.2/gems/activesupport-3.2.13/lib/active_support/callbacks.rb:385:in `_run_setup_callbacks'
          /home/gregory/.gem/ruby/1.9.2/gems/activesupport-3.2.13/lib/active_support/callbacks.rb:81:in `run_callbacks'
          /home/gregory/.gem/ruby/1.9.2/gems/activesupport-3.2.13/lib/active_support/testing/setup_and_teardown.rb:35:in `run'
```


** Comment unbatching fiasco**

Talk about the problems encountered while working on #165, and how it gradually
lead me to start getting very sloppy.

Leading to this horrible result, a syntax error deployed!
http://i.imgur.com/70gK6jj.png

Squash four trivial typos, then take a break!
http://i.imgur.com/JgfwsVu.png

** Fixing comment linking bugs and making user share tokens visible publicly **

Discuss how several semi-related features were getting log-jammed (#165, #169, #173)
