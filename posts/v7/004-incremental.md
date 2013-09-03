When you look at the photograph of highway construction shown below, what do you see?

![](http://i.imgur.com/eej11xZ.jpg)

If your answer was "ugly urban decay", then you are absolutely right! But because this construction project is only a few miles away from my house, I can tell you a few things about it that reveal a far more interesting story:

* On the far left side of the photo, you can see the first half of a newly constructed suspension bridge. At the time this picture was taken, it was serving five lanes of northbound traffic.

* Directly next to that bridge, cars are driving southbound on what was formerly the northbound side of our old bridge, serving 3 lanes of traffic.

* Dominating the rest of the photograph is the mostly deconstructed southbound side of our old bridge, a result of several months of active work.

So with those points in mind, what you are looking at here is an *incremental improvement* to a critical traffic bottleneck along the main route between New York City and Boston. This work was accomplished with hardly any service interruptions, despite the incredibly tight constraints on the project. This is legacy systems work at the highest level, and there is much we can learn from it that applies equally well to code as it does to concrete.

## Case study: Improving one of Practicing Ruby's oldest features

Now that we've set the scene with a colorful metaphor, it is time to see how these ideas can influence the way we work on software projects. To do that, I will walk you through a major change we made to practicingruby.com that involved a fair amount of legacy coding headaches. You will definitely see some ugly code along the way, but hopefully a bit of cleverness will shine through as well.

The improvement that we will discuss is a complete overhaul of Practicing Ruby's content sharing features. Although I've encouraged our readers to share our articles openly since our earliest days, several awkward implementation details made this a confusing process:

* You couldn't just copy-paste links to articles. You needed to explictly click a share button that would generate a public share link for you.

* If you did copy-paste an internal link from the website rather than explicitly generating a share link, those who clicked on that link would be immediately asked for registration information without warning. This behavior was a side-effect of how we did authorization and not an intentional "feature", but it was super annoying to folks who encountered it.

* If you visited a public share link while logged in, you'd see the guest view rather than the subscriber view, and you'd need to click a "log in" button to see the comments, navbar, etc.

* Both internal paths and share paths were completely opaque (e.g. "articles/101" and "/articles/shared/zmkztdzucsgv"), making it hard to know what a URL pointed to without
visiting it.
 
Despite these flaws, subscribers did use Practicing Ruby's article sharing mechanism. They also made use of the feature in ways we didn't anticipate -- for example, it became the standard workaround for using Instapaper to read our content offline. As time went on, we used this feature for internal needs as well, whether it was to give away free samples, or to release old content to the public. To make a long story short, one of our most awkward features eventually also became one of the most important.

We avoided changing this system for quite a long while because we always had something else to work on that seemed more important to us. But after enough time had passed, we decided to pay down our debts. In particular, we wanted to make the following changes to our sharing mechanism:

* We wanted to switch to subscriber-based share tokens rather than generating a new share token for each and every article. As long as a token was associated with an active subscriber, it could then be used to view any of our articles.

* We wanted to clean up and unify our URL scheme. Rather than having internal path like "/articles/101" and share path like "/articles/shared/zmkztdzucsgv", we would have a single path for both purposes that looked like this:

```
/articles/improving-legacy-systems?u=dc2ab0f9bb
```

* We wanted to make sure to be smart about authorization. Guests who visited a link with a valid share key would always see the "guest view" of that article, and logged in subscribers would always see the "subscriber view". If a key was invalid or missing, a guest would be explicitly told that the page was protected, rather than dropped into our registration process without warning.

* We wanted to make sure to make our links easy to share by copy-paste, from pretty much anywhere within our web interface, from the browser location bar, and also in our emails. This meant making sure we put your share token pretty much anywhere you might click on an article link.

Laying out this set of requirements helped us figure out where the destination was, but we knew intuitively that the path to get there would be a long and winding road. The system we initially built for sharing articles did not take any of these concepts into account, and so we would need to find a way to shoehorn them in without breaking old behavior in any significant way. We also would need to find a way to do this *incrementally*, to avoid releasing a ton of changes to our system at once that could be difficult to debug and maintain. The rest of this article describes how we went on to do exactly that, one pull request at a time.

> **NOTE:** Throughout this article, I link to  the"files changed" view of pull requests to give you a complete picture of what changed in the code, but understanding every last detail is not important. It's fine to dig deep into some pull requests while skimming or skipping others.

## Step 1: Hide the robobar

If you've been a subscriber to Practicing Ruby for long enough, you probably have seen this little guy poking out from the bottom of articles, like a cheap rip-off of Microsoft's Clippy:

![](http://i.imgur.com/UeG5rT3.png)

We had two ways to generate share links, but we want to move towards "zero". We killed Robobar, 
because it was obviously an unfinished work.

However, extraction would be hard, so we hid it instead. Had to delete some tests
to get things back to green, but they were areas that will go away.

> HISTORY: Deployed 2013-07-19, then merged the next day. 
>
>[View complete diff](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/125/files)

## Step 2: Make authorization failures explicit 

(PICTURE HERE)

This is a problem that would largely go away once the new system was in place. However, there 
would still be old links lingering around, and this problem was happening regularly
enough to be annoying.

Relatively simple fix (albeit with one hiccup that caused us to pull it from
deployment temporarily) and it solved this particular problem a month
before we were able to ship the more general solution.
 
When we found a bug, it hinted at a hole in our test suite which I filled.

> HISTORY: Deployed 2013-07-26 and then reverted a few days later due to a minor bug affecting registrations. Redeployed on 2013-08-06, then merged three days later. 
>
>[View complete diff](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/145/files)

---

## Step 3: Add article slugs

Relatively painless change that we were able to deploy same day as we developed it.
Adding all the slugs took much longer than that, and we didn't want to break /articles/id,
but it had a partial benefit right away.

[pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/155/files)

> HISTORY: FIXME. + Adding slugs was a manual process, so they didn't get fully populated until about a week after this feature shipped.

## Step 4: Add subscriber share tokens


[pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/158)

This was one of those requests where 80% of the time was spent on the first 80% of the problem, and the other 80% of the time was spent on the remaining 20%.

We got this shipped into production quickly (and rightly so, because it was only a useless parameter at that time, meant to allow us to make sure it ended up in all the right places), but then quickly realized the difficulty of writing this code in a DRY fashion.

Eventually settled on adding a path helper override (`article_path`, `article_url`) which delegates to a low level object (ArticleLink). Where we were confident we'd have our ApplicationHelper and settle on its default behavior, we used the override, otherwise we explicitly make calls to ArticleLink.

We had to dig way deeper into Rails core behavior than I wanted to in this code
(`to_params`, `Rails.app.routes.url_helpers`, Capybara, `assert_url_has_param` in test helper, etc). But we decided to do the best we could, and to ship with warts and all.

Somewhat ambitiously added some (wrong) code for conversation tokenizing here too.

> HISTORY: FIXME

## Step 5: Redesign and improve broadcast mailer

[pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/162)

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

> HISTORY: FIXME

## Step 6: Support share tokens in broadcast mailer

 [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/165)
 
Originally I had planned to take care of both broadcast emails and conversation mail at the same time,
but forgot that we still had not unrolled the conversation mailer.

We decided to add the broadcast tokenization even without the performance issues fixed, because it'd be something
I could put up with once or twice if absolutely necessary.
  
Only minor hiccup was with the test mailer, but I was able to fix that with a fake user shim.
Patch was straightforward otherwise.

> HISTORY: FIXME

## Step 7: Allow guest access to articles via share tokens

[pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/173/files)

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

> HISTORY: FIXME

## Step 8: Get the app running on an upgraded VPS

 [pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/174)

Jordan amazingly got this up and running. But I had to assume he might
not get to it before publishing.

(discuss more details)

> HISTORY: FIXME


## Step 9: Process broadcast mails using DelayedJob

[pull request](https://github.com/elm-city-craftworks/practicing-ruby-web/pull/164)

- Discuss delayed job, and how we tested in development by creating thousands of
  users and realized it's definitely slow.

- Talk about how we ran into problems with DelayedJob due to 1.9.2 and
  temporarily deployed the slow code.

- Once new server was up and running, tested this the same way as before,
create a bunch of users and turn off the delayed job processing.

- After we imported *real* users, we tested again by using the new server
to send out our maintenance emails. (necessary for "end to end" including
sendgrid)

> HISTORY: FIXME

## Step 10: Migrate to our new VPS

Mostly a painless cut over (see pull request for steps involved)

* Minor github oauth configuration issue (caught by mixpanel)
* Lack of Ruby 2.0 compatibility for Hominid (had to switch to MailChimp gem.
Luckily we used a ports-and-adapters style here so the change was trivial!)
https://github.com/elm-city-craftworks/practicing-ruby-web/pull/177/files

> HISTORY: FIXME

  
## CLOSING THOUGHTS

Wishlist:

* Overhaul sharing UI and add documentation similar to Ramen's
* Add tokenized comment emails 
* Add an option for credit me (used to be on for all, now off for all)
* Tweak shared article view (maybe add comment count + other stuff about PR?, maybe float bar?)
  

* Lots of old bad decisions (or non-decisions really) caught us... something easy to
happen on a side project, or on a limited budget / slow moving project. Even though 
PR is my main job, pr.com is very much a side project for Jordan and I.

* Lack of familiarity with the framework, and lack of currentness in my
experience bit me in many places. Even if I understood our current code,
those issues got in the way of changing it.

* Was it worth it? For us, yes. We're not on a fixed budget or timeline,
and I got to write this article. If I was billing $XXX/hr, I'm not sure
if I'd work on this without wondering *what else* might be lower hanging fruit.


> Special thanks goes to Jordan Byron (the maintainer of practicingruby.com) for collaborating with me on this article, and for helping Practicing Ruby run smoothly over the years.
