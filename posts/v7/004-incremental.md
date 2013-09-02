When you look at the photograph of highway construction shown below, what do you see?

![](http://i.imgur.com/eej11xZ.jpg)

If your answer was "ugly urban decay", then you are absolutely right! But because this construction project is only a few miles away from my house, I can tell you a few things about it that reveal a far more interesting story:

* On the far left side of the photo, you can see the first half of a newly constructed suspension bridge. At the time this picture was taken, it was serving five lanes of northbound traffic.

* Directly next to that bridge, cars are driving southbound on what was formerly the northbound side of our old bridge, serving 3 lanes of traffic.

* Dominating the rest of the photograph is the mostly deconstructed southbound side of our old bridge, a result of several months of active work.

So with those points in mind, what you are looking at here is an *incremental improvement* to a critical traffic bottleneck along the main route between New York City and Boston. This work was accomplished with hardly any service interruptions, despite the incredibly tight constraints on the project. This is legacy systems work at the highest level, and there is much we can learn from it that applies equally well to code as it does to concrete.

## Case study: Improving one of Practicing Ruby's oldest features

Now that we've set the scene with a colorful metaphor, it is time to see how these ideas can influence the way we work on software projects. To do that, I will walk you through a major change we made to practicingruby.com that involved a fair amount of legacy coding headaches. You will definitely see some ugly code along the way, but hopefully a bit of cleverness will shine through as well.

The improvement that we will discuss is essentially a complete overhaul to our mechanism for sharing Practicing Ruby's content with non-subscribers. I've encouraged our readers to share our content openly since our earliest days, but there were several implementation details that made this an awkward process:

* You couldn't just copy-paste links to our articles. You needed to explictly click a share button that would generate a public share link for you.

* If you did copy-paste an internal link from our website rather than explicitly generating a share link, those who clicked on that link would be immediately launched into our registration process without warning. This behavior was a side-effect of how we did authorization and not an intentional "feature", but it was super annoying to folks who encountered it.

* If you visited a public share link while logged in, you'd see the guest view rather than the subscriber view, and you'd need to click a "log in" button to see the comments, navbar, etc.

* Both our internal links and our share links were completely opaque (e.g. "articles/101" and "/articles/shared/zmkztdzucsgv"), making it impossible to see what they pointed to
 before you clicked the link.
 
Despite these flaws, subscribers did continue to use our sharing mechanism. They even made use of the feature in ways we didn't anticipate: it became the standard workaround for using Instapaper and other offline reading tools that need public access to work correctly. As time went on, we used this feature for our internal use as well, whether it was to give away free samples of our content, or to release old content to the public. To make a long story short, one of our most awkward features eventually also became one of the most important.

From time to time, we thought about how we might go about improving this system, but we were always scared off by the amount of work it would require to make significant changes to it. In fact, it took a combination of Practicing Ruby's move to a monthly publication schedule and my realization that I wanted to write an article about incrementally improving legacy systems to get us to the point where we were willing to seriously consider doing the work. Once we committed to the project, we came to realize that the changes we wanted were at least simple to describe:

* We wanted to switch to subscriber-based share tokens rather than generating a new share token for each and every article. As long as a token was associated with an active subscriber, it could then be used to view any of our articles.

* We wanted to clean up and unify our URL scheme. Rather than having internal path like "/articles/101" and share path like "/articles/shared/zmkztdzucsgv", we would have a single path for both purposes that looked like this:

```
/articles/improving-legacy-systems?u=dc2ab0f9bb
```

* We wanted to make sure to be smart about authorization. Guests who visited a link with a valid share key would always see the "guest view" of that article, and logged in subscribers would always see the "subscriber view". If a key was invalid or missing, a guest would be explicitly told that the page was protected, rather than dropped into our registration process without warning.

* We wanted to make sure to make our links easy to share by copy-paste, from pretty much anywhere within our web interface, from the browser location bar, and also in our emails. This meant making sure we put your share token pretty much anywhere you might click on an article link.

Laying out this set of requirements helped us figure out where our destination was, but we knew intuitively that the path to get there would be a long and winding road. The system we initially built for sharing articles did not take any of these concepts into account, and so we would need to find a way to shoehorn them in without breaking old behavior in any significant way. We also would need to find a way to do this *incrementally*, to avoid releasing a ton of changes to our system at once that could be difficult to debug and maintain. The rest of this article describes how we went on to do exactly that, one pull request at a time.

(Get Day Numbers so people can get a sense on when each thing was available)
(USE BOARD TO DETERMINE PULL REQUESTS TO DISCUSS)

---

> Special thanks goes to Jordan Byron (the maintainer of practicingruby.com) for collaborating with me on this article, and for helping Practicing Ruby run smoothly over the years.



> TODO: SPLIT PULL REQUESTS INTO DISCUSSION / "Files Changed" DIFF
> Should we include diffs inline or code samples where relevant, or just link?

# READ ALL PULL REQUESTS CAREFULLY AND ALSO THINK BACK ABOUT CHALLENGES, NOTES BELOW ARE JUST "TOP OF THE HEAD" SKETCHES.

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


**Adding slugs -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/155/files)**

Relatively painless change that we were able to deploy same day as we developed it.
Adding all the slugs took much longer than that, and we didn't want to break /articles/id,
but it had a partial benefit right away.

**Adding user tokens -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/158)**

This was one of those requests where 80% of the time was spent on the first 80% of the problem, and the other 80% of the time was spent on the remaining 20%.

We got this shipped into production quickly (and rightly so, because it was only a useless parameter at that time, meant to allow us to make sure it ended up in all the right places), but then quickly realized the difficulty of writing this code in a DRY fashion.

Eventually settled on adding a path helper override (`article_path`, `article_url`) which delegates to a low level object (ArticleLink). Where we were confident we'd have our ApplicationHelper and settle on its default behavior, we used the override, otherwise we explicitly make calls to ArticleLink.

We had to dig way deeper into Rails core behavior than I wanted to in this code
(`to_params`, `Rails.app.routes.url_helpers`, Capybara, `assert_url_has_param` in test helper, etc). But we decided to do the best we could, and to ship with warts and all.

Somewhat ambitiously added some (wrong) code for conversation tokenizing here too.

**Make broadcast mailer send individual emails + added mustache -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/162)**

Here we were bit by another Rails core oddity: The way we were using
ActionMailer was wrong, and so ActionMailer::Base.deliveries was delivering
corrupt results. This lead to a very annoying debugging session. (If you
reproduce, check `object_id` out of curiousity).

This work also left us looking at some ugliness in our tests which we couldn't deal with at the moment, but exposed issues to return to later.

By the end of it, we had mustache URL expansion `{{article}}slug{{/article}}` but not tokens.

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

**Tokenized Emails (really just broadcasts) -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/165)**

Originally I had planned to take care of both broadcast emails and conversation mail at the same time,
but forgot that we still had not unrolled the conversation mailer.

We decided to add the broadcast tokenization even without the performance issues fixed, because it'd be something
I could put up with once or twice if absolutely necessary.
  
Only minor hiccup was with the test mailer, but I was able to fix that with a fake user shim.
Patch was straightforward otherwise.

**Diversion? Comment anchoring -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/169)**

This is a bug that we vaguely were aware of before, but became more noticeable during testing.
(Also, the login button on the shared page).

We prioritize bugs over feature work (even in these circumstances) so I started on a fix for this and learned that anchors are never submitted to the server (took some digging, due to my ignorance). The way I solved this turned out to be *incompatible* with the other changes I wanted to make though... so this was deployed temporarily and later stalled as I worked on token integration.
  
(closed without merging)

**Share by User Token -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/173/files)**

This is where the bulk of the "new behavior" actually got wired up.
In particular, the following behavior changes happened:

- Logged in users will see full article w. comments as normal
- With a valid token, guests will see the "shared article" view
- Without a valid token, guests will see the "that page is protected" error
- Expired subscriptions now invalidate share links
- Admin checks are no longer done on drafts (but the articles are only visible to those with the link)
- Login button on share pages no longer redirects to practicingruby.com landing page first
- Old share links redirect to user token links

This is entirely too many changes to make at once, but there wasn't an easy way to separe 
them meaningfully without creating inconsistent or awkward behavior. Although in hindsight
there might be ways to separate at least some of these features, most had at least partially
shared dependencies.

I started this out as a spike, not expecting it to work, but then found a path forward 
that wasn't *terrible* (even though it was far from pretty). Because reverting is cheap,
I let this code run live for a couple days and caught a couple minor bugs that way (these
caused weird behaviors, but nothing major)

Because this code itself was a) built on a foundation that may need some cleanup once the
dust settles and b) needed to be in place to enable some future work, I viewed it as
a temporary bit of tech debt that we promised ourselves to pay off whenever the
bad code is along our critical paths.

**New Server!! -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/174)**

Jordan amazingly got this up and running. But I had to assume he might
not get to it before publishing.

Mostly a painless cut over (see pull request for steps involved)

Hiccups:

* Minor github oauth configuration issue (caught by mixpanel)
* Lack of Ruby 2.0 compatibility for Hominid (had to switch to MailChimp gem.
Luckily we used a ports-and-adapters style here so the change was trivial!)
https://github.com/elm-city-craftworks/practicing-ruby-web/pull/177/files


**Delayed broadcast mailer -- [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/164)**

- Discuss delayed job, and how we tested in development by creating thousands of
  users and realized it's definitely slow.

- Talk about how we ran into problems with DelayedJob due to 1.9.2 and
  temporarily deployed the slow code.

- Once new server was up and running, tested this the same way as before,
create a bunch of users and turn off the delayed job processing.

- After we imported *real* users, we tested again by using the new server
to send out our maintenance emails. (necessary for "end to end" including
sendgrid)


## REMAINING ISSUES:

Consider cutting this section or limiting only to clear missing pieces
(i.e. removing cruft, sharing docs, etc.)
  
If small enough, roll into "closing thoughts"

Wishlist:

* Overhaul sharing UI and add documentation similar to Ramen's
* Add tokenized comment emails 
* Add an option for credit me (used to be on for all, now off for all)
* Tweak shared article view (maybe add comment count + other stuff about PR?, maybe float bar?)
  
  
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



- Discuss delayed job, and how we tested in development by creating thousands of
  users and realized it's definitely slow.

- Talk about how we ran into problems with DelayedJob due to 1.9.2 and
  temporarily deployed the slow code.


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
