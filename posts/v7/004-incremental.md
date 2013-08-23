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


