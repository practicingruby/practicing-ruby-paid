**BIO GOES HERE**

Rstat.us is a microblogging site that is similar to Twitter, but it's built using
open standards ([OStatus](http://ostatus.org/)). It's designed to be federated so
that anyone can run rstat.us' code on their own domain but be able to follow anyone
on other domains. The largest problem currently impeding user adoption is the lack
of a mobile client, which is due to the lack of an API.

We have been exploring two different types of APIs for possible implementation for
rstat.us: a hypermedia API using the ALPS microblogging spec and a JSON API that is
compatible with Twitter's API. This article will define what each of those types are,
compare their advantages and disadvantages in the context of rstat.us, and discuss
the decision we have made for rstat.us' current development.

## Hypermedia API

Hypermedia APIs currently have a reputation for being complicated and hard to
understand, but they're really nothing to be scared of. There are many, many
articles about what hypermedia is or is not, but the general definition that
made hypermedia click for me is that a hypermedia API returns links in its
responses that the client then uses to make its next calls. This means the
server does not have a set of URLs with parameters documented for you up front;
it has documentation of the controls that you will see within the responses.

The specific hypermedia API type that we are considering for rstat.us is one
that complies with the [Application-Level Profile Semantics (ALPS) microblogging
spec](http://amundsen.com/hypermedia/profiles/). This spec is an experiment
started by Mike Amundsen to explore the advantages and disadvantages of multiple
client and server implementations agreeing only on what particular values for
the XHTML attributes `class`, `id`, `rel`, and `name` signify. The spec does not
contain any URLs, example queries, or example responses.

Here is a subset of the ALPS spec attributes and definitions; these have to do
with the rendering of one status update and its metadata:

- li.message - A representation of a single message
- span.message-text - The text of a message posted by a user
- span.user-text - The user nickname text
- a with rel 'message' - A reference to a message representation

Here is one way you could render an update that is compatible with these ALPS spec attributes:

```html
<li class="message">
  <span class="message-text">
    I had a fantastic sandwich at Primanti's for lunch.
  </span>
  <span class="user-text">Carols10cents</span>
  <a rel="message" href="http://rstat.us/12345">(permalink)</a>
</li>
```

And here is another way that is also compatible:

```html
<li class="message even">
  <p>
    <a rel="permalink message" href="http://rstat.us/update?id=12345">
      <span class="user-text">Carols10cents</span> said:
    </a>
    <span class="message-text">
      I had a fantastic sandwich at Primanti's for lunch.
    </span>
  </p>
</li>
```

Notice some of the differences between the two:

- All the elements being siblings vs some nested within each other
- Only having the ALPS attribute values vs having other classes and rels as well
- Only having the ALPS elements vs having the `<p>` element 
between the `<li>` and the rest of the children
- The URLs of the permalinks are different

All of these are perfectly fine! If the client only depends on the values of the
attributes and not the exact data structure that's returned, it will be flexible
enough to handle both these responses.

Here is how a client could extract this update's author's username using
[Nokogiri](http://nokogiri.org) on either of these fragments, using CSS
selectors:

```ruby
require 'nokogiri'

# Create a Nokogiri HTML Document from the first example, the second example 
# could be substituted and the result would be the same
html = <<HERE
  <li class="message">
    <span class="message-text">
      I had a fantastic sandwich at Primanti's for lunch.
    </span>
    <span class="user-text">Carols10cents</span>
    <a rel="message" href="http://rstat.us/12345">(permalink)</a>
  </li>
HERE

doc = Nokogiri::HTML::Document.parse(html)

# Using CSS selectors
username = doc.css("li.message span.user-text").text 
```

With this kind of contract, we have the flexibility to change the representation
of an update by the server from the first format to the second without breaking
client functionality.

## JSON API

JSON APIs are much more common than hypermedia APIs right now. This style of API typically has a published list of URLs, one for each action a client may want to take. Each URL also has a number of documented parameters in which a client can send arguments, and the requests return data in a defined format (JSON is popular). This style is more like making a Remote Procedure Call (RPC) -- calling functions with arguments and receiving return values but the work is being done on a remote machine. I think it's popular because it matches the way we code locally; it feels familiar.

[Twitter's API](https://dev.twitter.com/docs/api) is currently in this style. There's a lot of documentation about all the URLs available, what parameters they take, and what the returned data or resulting state will be.

For example, here is how you would get the text of the 3 most recent tweets made by user @climagic with Twitter's JSON API ([relevant documentation](https://dev.twitter.com/docs/api/1/get/statuses/home_timeline)):

```ruby
require 'open-uri'
require 'json'

# Make a request to the home_timeline resource with the format json.
# Pass the parameter screen_name with the value climagic and the 
# parameter count with the value 3.

base = "http://api.twitter.com/1/statuses/user_timeline.json"
uri  = URI("#{base}?screen_name=climagic&count=3")

# The response object is a list of tweets, which is documented at
# https://dev.twitter.com/docs/platform-objects/tweets

response = JSON.parse(open(uri).read)

tweets = response.collect { |t| t["text"] }
```

Rendering JSON from the server is usually fairly simple as well, and I think
the simplicity of providing and consuming JSON using many different languages
is one of the big reasons JSON APIs are gaining in popularity. Twitter
actually decided to [drop support for XML, RSS, and
Atom](https://dev.twitter.com/docs/api/1.1/overview#JSON_support_only) in
version 1.1 of their API, leaving ONLY support for JSON. [According to
Programmable
Web](http://blog.programmableweb.com/2011/05/25/1-in-5-apis-say-bye-xml/) 20%
of new APIs released in 2011 offered only JSON support.


### Comparing and contrasting the two styles

There are many clients that have been built against Twitter's current API. There
are even some clients that allow you to change the root URL of all the requests
(ex:
[Twidere](https://play.google.com/store/apps/details?id=org.mariotaku.twidere)),
so that if rstat.us implemented the exact same parameters and return data,
people could use those clients and tell them to request
`http://rstat.us/statuses/user_timeline.json` instead and immediately have an
rstat.us client. Even if rstat.us doesn't end up having that level of
compatibility, if we offer an API in this same style, developers of other
clients would already be familiar with how to use it in general.

But do we want to be coupled to Twitter's API design? If Twitter changes a
parameter name, or a URL, or the structure of the data returned, and the clients
update to handle that, the rstat.us use of those clients will break as well. One
of the reasons rstat.us was started was to become less reliant on Twitter, after
all.

In addition to flexibility in the exact representation provided by the server
and consumable by the client, another advantage of a hypermedia API is that the
media type used here is XHTML-- and we just so happen to already have an XHTML
representation of rstat.us' functionality, rstat.us' web interface itself! If
you take a look at the source of [http://rstat.us](http://rstat.us), you can see
that the markup for an update contains the attribute values we've been talking
about. rstat.us isn't completely compliant with the spec yet, but adding
attributes to our existing output [has been fairly
simple](https://github.com/hotsh/rstat.us/commit/4e234556c73426dc16526883661b3feb1e2f7d9f).
Building out a Twitter-compatible JSON API would mean reimplementing an almost
entirely separate interface to rstat.us' functionality that we would then need
to maintain consistency with the core of rstat.us itself _as well as_ with
Twitter.

But, looking at the source of http://rstat.us again, you'll also see a lot of
other information in the source of the page. Most of it isn't needed for the use
of the API, so we're transferring a lot of unnecessary data back and forth. The
JSON responses are very compact in comparison; over time and with scale, this
could make a difference in performance.

Another concern I have is that some operations that are straightforward with a
Twitter-style JSON API, such as getting one user's updates given their username,
seem complex when following the ALPS spec. With the JSON API, there is a
predefined URL with the username as a parameter, and the response would contain
the user's updates. With the ALPS spec, starting from the root URL (which is the
only predefined URL in an ideal hypermedia API), we would need to do a minimum
of 4 HTTP requests:

```ruby
require 'nokogiri'
require 'open-uri'

USERNAME = "carols10cents"
BASE_URI = "https://rstat.us/"

def find_a_in(html, params = {})
  raise "no rel specified" unless params[:rel]

  # This XPath is necessary because @rels could have more than one value.
  link = html.xpath(
    ".//a[contains(concat(' ', normalize-space(@rel), ' '), ' #{params[:rel]} ')]"
  ).first
end

def resolve_relative_uri(params = {})
  raise "no relative uri specified" unless params[:relative]
  raise "no base uri specified" unless params[:base]

  (URI(params[:base]) + URI(params[:relative])).to_s
end

def request_html(relative_uri)
  absolute_uri = resolve_relative_uri(
    :relative => relative_uri,
    :base     => BASE_URI
  )
  Nokogiri::HTML::Document.parse(open(absolute_uri).read)
end

# Request the root URL
# HTTP Request #1
root_response = request_html(BASE_URI)

# Find the `a` with `rel=users-search` and follow its `href`
# HTTP Request #2
users_search_path = find_a_in(root_response, :rel => "users-search")["href"]
users_search_response = request_html(users_search_path)

# Fill out the `form` that has `class=users-search`,
# putting the username in the `input` with `name=search`

search_path = users_search_response.css("form.users-search").first["action"]
user_lookup_query = "#{search_path}?search=#{USERNAME}"

# HTTP Request #3
user_lookup_response = request_html(user_lookup_query)

# Find the search result beneath `div#users ul.search li.user` that has
# `span.user-text` equal to the username
search_results = user_lookup_response.css("div#users ul.search li.user")

result = search_results.detect { |sr|
  sr.css("span.user-text").text.match(/^#{USERNAME}$/i)
}

# Follow the `a` with `rel=user` within that search result
# HTTP Request #4
user_path = find_a_in(result, :rel => "user")["href"]
user_response = request_html(user_path)

# Extract the user's updates using the update attributes.
updates = user_response.css("div#messages ul.messages-user li")
puts updates.map { |li| li.css("span.message-text").text.strip }.join("\n")
```

This workflow could be cached so that the next time we try to get a user's
updates, we wouldn't have to make all of these HTTP requests. The first two
requests for the root page and the user search page are unlikely to change
very often, so when we get a new username we can start with the construction
of the user_lookup_query with a cached search_path value. That way, we would
only need to make the last two HTTP requests to look up subsequent users. If
the root page or the user search page DO change, however, then our cache will
be stale and the subsequent requests could fail. In that case, we should have
error handling code that clears the cache and tries starting from the root
page again.

Another alternative is extending the ALPS spec to include, for example, a URI
template with a `rel` attribute to indicate that it's a transition to
information about a user when the template is filled out with the username.
The ALPS spec path would still work, but this would be a shortcut that clients
could take to reduce the number of HTTP requests. However, since it wouldn't
be an official part of the spec, we would need to add documentation about it.
Clients trying to use APIs that do not provide this extension would need to
support both the shortcut and the ALPS spec path anyway.

### Outcome

After weighing all these considerations, we've decided to concentrate first on
implementing a Twitter-compatible JSON API. Being able to use existing,
functioning clients is probably the most compelling reason. Should those not end
up working, having an API in a style already familiar to many client developers
is also a big plus. For the long term, I think having a more flexible and
scalable solution is more important but these aren't really something we need
until there is more adoption. So we may implement a hypermedia API, probably an
extension of the ALPS spec, in the future.

### References

- [rstat.us](http://rstat.us) and its [code on github](https://github.com/hotsh/rstat.us)
- [ALPS microblogging spec](http://amundsen.com/hypermedia/profiles/)
- [Designing Hypermedia APIs](http://designinghypermediaapis.com) by Steve Klabnik
- [A Shoes hypermedia client for ALPS microblogging](https://gist.github.com/2187514)
- [Twitter API docs](https://dev.twitter.com/docs/api)
- [REST APIs must be hypertext-driven](http://roy.gbiv.com/untangled/2008/rest-apis-must-be-hypertext-driven)
