> DISCLAIMER: The examples in this article are Rails-based, and I'm only an intermediate Rails developer at best. The focus of this article is on general maintenance patterns rather than specific implementation details, but if you see something ugly in the code samples, please give me some feedback!

When I launched the Practicing Ruby journal back in August 2011, I was just as excited about designing my own publishing software as I was about working on new articles. After several unsuccessful attempts at using existing services, I had finally thrown in the towel and decided that for this journal to be what I wanted it to be, it needed to run on its own custom software.

For the first few weeks, I was adding new bits of functionality as quickly as [Jordan Byron](http://community.mendicantuniversity.org/people/jordanbyron) and I could code them up. However, by mid-October we had built a tool that was good enough for day-to-day use, and I was generally happy with our progress. The unfortunate consequence of reaching that stabilizing point was that as I focused more and more on my writing work, our plans to gradually roll out some "nice to have" features eventually faded into the background. While this was a reasonable trade to make at the time, the growing resistance to improving our underlying infrastructure gradually chipped away at me until I decided to do something about it. 

In March 2012, we resumed active maintenance on [Practicing Ruby's codebase](https://github.com/elm-city-craftworks/practicing-ruby-web) after several months of allowing it to stagnate. The process of doing so reminded me of several patterns that I like to apply when working with legacy code, no matter what the underlying context is. In this article I'll review those patterns in the hopes that they will be useful for your projects, too.

### 1) Get exception notifications set up right away

One of the biggest costs of being away from a project for a while is that you end up losing a sense of its quirks and nuances. Without remembering where the dark corners are, it is hard to say with confidence that the changes you introduce won't break something else, even if the project is well tested. If we assume that at least a few failures will happen during the process of shaking the cobwebs off a codebase, then we need to work towards mitigating their impact rather than avoiding them entirely. With this in mind, a good first step is to set up some sort of exception notification system so that newly introduced defects get discovered quickly.

Because this is a common problem for Rails developers, there are a lot of different tools out there that are specifically designed to make automated error reporting easy. The one that I ended up using for Practicing Ruby is the [exception_notification](https://github.com/rails/exception_notification) gem, which is a simple rack middleware that will send email-based error reports whenever your application raises an exception. Because the application was already configured to send emails, adding exception notification was as easy as adding `exception_notifier` to the Gemfile and then creating an initializer with the following code in it:

```ruby
if Rails.env.production?
  PracticingRubyWeb::Application.config.middleware.use ExceptionNotifier,
    :email_prefix => "[Practicing Ruby] ",
    :exception_recipients => %w{gregory.t.brown@gmail.com jordan.byron@gmail.com}
end
```

In other contexts, the cost of adding exception notification may be slightly higher, but is still worth doing. In the past I've built little scripts which would email me when scheduled jobs failed, or tried to make it easy for users to email me detailed error reports from standalone applications. While it isn't a good idea to treat the users of your software as if they were QA testers, the benefit of a system in use is that you'll gain insights about paths through your application that you wouldn't necessarily think to test on your own. Additionally, the information gained from these kinds of error reports makes it easy to put together integration tests and unit tests that will guard against future regressions.

In order to be effective, exception notification needs to be as frictionless as possible, both for the user and the developer. In an ideal setup, failures are automatically reported in a way that is completely transparent to the user, and each report should contain enough information so that a developer can investigate the problem right away. While it won't be possible to perfectly adhere to these lofty goals on all projects in all contexts, they form a solid standard to shoot for. 

It is worth noting that you may run into some minor obstacles when introducing an exception notifier to a project which hasn't been using one all along. In particular, there may be some weird edge case scenarios which are causing failures to occur in your application even though they do not affect its day-to-day use. These failures will generate a bunch of noise, and if you don't deal with them or filter them in some way, it will cause the more rare but legitimate failure reports from getting the attention they deserve.

As a specific example of this problem, [a minor flaw in Rails](https://github.com/rails/rails/issues/4127) has been causing Google's indexing bots to raise `MissingTemplateError` exceptions. My workaround for the time being has been to set up email filters to delete exceptions reports triggered by Google's bots, and so far that has made sure that I only receive legit exception reports in my inbox. Speaking more generally, it is essential to make sure your exception handler does not become ["the boy who cried wolf"](http://en.wikipedia.org/wiki/The_Boy_Who_Cried_Wolf), even if it comes at the cost of silencing a few legitimate but low priority failure reports. 



### 5) Cast a wide net when writing tests

In the early stages of a project, it is common to take a relaxed attitude towards automated testing until the core ideas behind the product begin to take shape. When done in a disciplined way, rapid prototyping can provide insights into the problem domain that might otherwise be missed by the traditional test-driven workflow. However, these insights come at the cost of accumulating technical debt that must eventually be paid down if a project needs to be maintained on an ongoing basis.

Dealing with this problem in legacy codebases is a delicate balancing act. On the one hand, a lack of adequate testing is one of the things that causes projects to fall into disrepair. On the other hand, just fixing bugs and adding tiny new features to a project that has been stalled for months or years can be such a slow process that it can be hard to find the time to focus specifically on improving code coverage. Effectively managing these competing interests is a key part of the process of bringing dormant projects back to life.

To deal with this problem, I try to treat each new change as an opportunity to make small test coverage improvements to both the feature I am working on and its collaborators. Over time, this practice increases coverage in the areas of the project that are being actively worked on, making each new change to those subsystems easier and easier. Using this technique, it is possible to let the needs of the product drive the efforts to improve the code, which is much more reliable than examining code quality and maintainability in the abstract.

As an example, the original implementation of the `beta_testers` helper method was built with the assumption that beta features would only exist on pages where the user was logged in. With that in mind, I assumed that the feature was so trivial it didn't need a test at all, and deployed the code into production. Within minutes, the exception notifier sent me an email with this exception:

```ruby
A ActionView::Template::Error occurred in articles#shared:

  undefined method `beta_tester?' for nil:NilClass
  app/helpers/application_helper.rb:15:in `beta_testers'

-------------------------------
Request:
-------------------------------

  * URL       : http://practicingruby.com/articles/shared/ggcwduoyfqmz

  # ... remainder of report omitted, unimportant ...
```

On its own, this failure report was an embarrassing reminder that even if you are working on a feature which does not need to be tested explicitly, that does not mean you should deploy without running your tests! Had I actually done that, I would have seen all of the following test cases raise the same exact error:

```ruby
test_Github_accounts_without_public_email_do_not_cause_errors(AccountLinkingTest):
test_Github_emails_are_downcased_automatically(AccountLinkingTest)
test_Mailchimp_emails_are_downcased_automatically(AccountLinkingTest)
test_Manually_entered_emails_are_downcased_automatically(AccountLinkingTest)
test_Revisiting_the_activation_link_displays_an_expiration_notice(AccountLinkingTest)
test_github_autolinking(AccountLinkingTest)
test_github_manual_linking(AccountLinkingTest)
test_broadcasts_are_only_visible_when_signed_in(BroadcastTest)
```

However, by comparing the error report and the names of the failed tests, I realized that none of my integration tests were currently directly testing the shared article page. There was some code in the broadcast tests which indirectly used a shared page as a way to check that broadcasts are not shown to visitors who are not logged in, but no simple test that said "shared articles are visible without logging in". With that in mind, I decided that this was a perfect time to add a test which did exactly that.

```ruby
class SharingTest < ActionDispatch::IntegrationTest
  setup do
    @authorization = Factory(:authorization)
    @user          = @authorization.user
    @article       = Factory(:article)
  end

  test "shared article visible without logging in" do
    assert_shared_article_accessible

    assert_no_content("Log out")
  end

  test "shared article visible to logged in users" do
    sign_user_in

    assert_shared_article_accessible

    assert_content("Log out")
  end

  def assert_shared_article_accessible
    share = SharedArticle.find_or_create_by_article_id_and_user_id(
      @article.id, @user.id)

    visit shared_article_path(share.secret)

    assert_equal shared_article_path(share.secret), current_path
  end
end
```

Running this test in isolation against the old implementation of the `beta_tester` helper reproduced the problem in a way that was very similar to the real failure report I received. Fixing it was as easy as applying the tiny change shown below:

```diff
   def beta_testers
-    yield if current_user.beta_tester?
+    yield if current_user.try(:beta_tester)
   end
```

If I was only focused on fixing the `beta_testers` defect, I may have just made this one line change without adding any new tests. However, because adding the `SharingTest` was an easy way to reproduce the defect while simultaneously explicitly defining one of Practicing Ruby's key features, I knew the extra work would be well worth the effort.

Extracting simple generalizations based on specific failure cases can be very valuable because capturing the essence of an external failure can guard against all sorts of different internal defects. While this technique isn't meant to be a substitute for test-driven development, it establishes a first line of defense against unexpected failures, and that is a key part of taming any project that has been neglected for a while.
