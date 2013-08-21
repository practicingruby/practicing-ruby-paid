**Fill in earlier steps here**

**User tokens**:

Start with URL design

(ramen music inspired, but using params instead of /route/token)

https://practicingruby.com/articles/exploratory-data-analysis?u=p1e02d30558

Had to figure out how to test URL params in Capybara

**Email templating**:

Debate between rolling my own and using a library

>> Mustache.render("Check out the article here:\n{{#article-url}}a-path-to-nowhere{{/article-url}}", "article-url" => ->(e) { articles[e]})
=> "Check out the article here:\nhttps://practicingruby.com/articles/101?u=kdsljsaldgjhgkdljsadgkl"

