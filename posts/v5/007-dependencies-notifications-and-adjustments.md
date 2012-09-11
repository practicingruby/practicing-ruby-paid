Object-oriented programming helps organize your code in a resilient,
easy-to-change way. This article aims to explore one of the concepts that trips
up beginner and more experienced object-oriented programmers: how to sensibly
connect a set of objects together to perform a complex task. How do you put
instances of your information-hiding, single-responsibility-discharging,
message-passing classes in touch with one another?

I became confused about the smartest ways to do this when I started building
Ruby apps that involved fetch large amounts of data from external services. In
these projects, a Rails or Sinatra web application acted as a facade for workers
querying a large set of APIs. Each API was different from the last, requiring
different approaches and different dependencies. Some APIs involved five or six
different steps, and in some cases each step needed to be handled by a different
object.

I felt I understand object-oriented programming pretty well, yet I struggled
with specifying the relationships between objects so that each object knew just
enough about its peers to get the job done. My style was inconsistent. Sometimes
I would inject a dependency using the constructor, and sometimes I would use a
setter method. At other times it seemed more natural to have an object directly
instantiate new instances of whatever objects it needed, on the fly.

### Object Peer Stereotypes

All of this changed when someone turned me onto the book [Growing Object
Oriented Software, Guided by Tests][GOOS] by Steve Freeman and Nat Pryce. The book has
a chapter on object-oriented design styles, and includes a description of
“Object Peer Stereotypes” that addressed my conundrum perfectly.

The authors divide an object’s peers into three categories: Dependencies,
Notifications, and Adjustments (DNA). These are rough categories, because an
object peer could fit into more than one category, but I found it to be a useful
distinction. We’ll explore each of these categories as they pertain to Ruby code
using an example from my real production code: a wrapper for Typhoeus I wrote
called HttpRequest.

By the way, Gregory wrote about a related topic (what types of arguments to pass
into a method) back in [Issue 2.14][2-14]. As your objects become more
sophisticated you’ll find you end up passing fewer basic object types like
strings, symbols, or numbers, and more of the Argument, Selector, or Curried
objects that Gregory describes.

### Dependencies

> Services that the object requires from its peers so it can perform its
> responsibilities. The object cannot function without these services. It should
> not be possible to create the object without them.

> ... we insist on dependencies being passed in to the constructor, but
> notifications and adjustment can be set to defaults and reconfigured later.

I wrote the HttpRequest class so that I could set on_success and on_failure
callbacks (where Typhoeus only provides an on_complete callback) and to
encapsulate my dependency on the Typhoeus gem, in case I want to switch to
another HTTP library later.

HttpRequest objects have two Dependencies: the URL of the request and a set of
options for telling Typhoeus how to make the request.

```ruby
require "typhoeus"

class HttpRequest
  attr_reader :typhoeus_request

  def initialize(url,options = {})
    @typhoeus_request = Typhoeus::Request.new(url,options)
    @success_callbacks = []
    @failure_callbacks = []

    @typhoeus_request.on_complete do |response|
      if response.success?
        success_callbacks.each { |sc| sc.call(response.body,"Success") }
      elsif response.timed_out?
        failure_callbacks.each { |sc| sc.call("Request timed out for #{url}") }
      elsif response.code == 0
        failure_callbacks.each do |sc| 
          sc.call("No HTTP response for #{url}: #{response.curl_error_message}") 
        end
      else
        failure_callbacks.each do |sc| 
          sc.call("HTTP request failed for #{url} (#{response.code})",response.body) 
        end
      end
    end
  end

  def on_success(&block)
    success_callbacks << block
  end

  def on_failure(&block)
    failure_callbacks << block
  end

  private

  # I picked this technique up from Gregory; I think it leads to fewer bugs
  attr_reader :success_callbacks, :failure_callbacks
end
```

Note that I’m supplying a default for the options argument, since it’s just a
hash that gets passed onto Typhoeus::Request, and it’s something you’ll have
available at the same type you have the URL. Because there is a sensible default
(an empty hash), you could argue that this argument is more of an Adjustment,
described below.

If options was a more complex object, something that might have peers of its
own, I would probably treat it as an Adjustment. I find test-driven development
really helpful in cases like this because often the tests can help you feel out
which approach is more appropriate (which is the whole premise of the Growing
Object Oriented Software book).

### Notifications

> Peers that need to be kept up to date with the object’s activity. The object
> will notify interested peers whenever it changes state or performs a
> significant action. Notifications are ‘fire and forget’; the object neither
> knows nor cares which peers are listening.

In the HttpRequest example, success_callbacks and failure_callbacks are the
notifications. Another object can register for success notifications like this:

```ruby
# how to use HttpRequest#on_success to register a Notification
stats_request.on_success do |body|
  xml = Nokogiri::XML(body)

  xml.xpath("//Audience").each do |aud|
    key = aud.at("id").text
    if dsh = datapoint_hashes.find { |dsh| dsh[:key] == key }
      dsh[:values][:abbreviation] = aud.at("abbreviation").text
    end
  end
  @success = true
end
```

Logging is another canonical notification example. Here’s a pattern I use a lot
for logging:

```ruby
class DataFetcher
  #make it easy to customize our object with a new notification 
  attr_writer :logger 

  def fetch
    # do important things
    logger.info("I did something important")
  end

  private

  def logger
    @logger ||= Logger.new(STDOUT)
  end 
end
```

Notifications can also be sent as arguments to a method call. I often pass a
block for error handling. I find this usually involves fewer lines of code than
returning a status object that must be tested for success or failure.

```ruby
data_fetcher.fetch do |err_msg|
  puts "We couldn't complete our task because of #{err_msg}"
  return
end

# do rest of our work, confident that data_fetcher succeeded
```

### Adjustments

> Peers that adjust the object’s behavior to the wider needs of the system. This
includes policy objects that make decisions on the object’s behalf...and
component parts of the object if it’s a composite.

Most of my Adjustments involve component parts of a composite object. For the
API-intense project where I’m using HttpRequest, I always have one class that
has overall responsibility for getting all of the data we need for each API.
That “master” class just does one thing: it coordinates the activities of a set
of Adjustment peers, are of which are set to sensible defaults:

```ruby
class DataFetcher
  # these are all Adjustments
  attr_writer :authorization_agent, :shaz_fetcher, :bot_fetcher

  attr_writer :logger

  def fetch(credentials)
    authorization_agent.login(credentials) do |err_msg|
      logger.warn "Could not login due to #{err_msg}"
      return
    end

    shaz_fetcher.fetch(authorization_agent.token) do |err_msg|
      logger.warn "Could not fetch shaz due to #{err_msg}"
    end

    bot_fetcher.fetch(shaz_fetcher.data) do |err_msg|
      logger.warn "Could not fetch bot due to #{err_msg}"
      return
    end
    
    # do something with results of bot_fetcher
  end

  private

  def authorization_agent
    @authorization_agent ||= AuthorizationAgent.new
  end

  def shaz_fetcher
    @shaz_fetcher ||= ShazFetcher.new
  end

  def bot_fetcher
    @bot_fetcher ||= BotFetcher.new
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end 
end
```

This also enables simple unit testing because you can so easily set the
adjustments to mock objects provided by the tests.

If you use the [strategy pattern][strategy], where peer objects make decisions
for your object, your Adjustment might look like this:

```ruby
class DataFetcher
  attr_writer :admin_checker

  def fetch(query_params)
    yield "You are not authorized to access that data" unless admin_checker.valid?(query_params)
    # proceed to fetch data
  end

  private

  def admin_checker
    @admin_checker ||= AdminChecker.new
  end
end
```

It could be that AdminChecker is more of a Dependency than an Adjustment,
depending on how many different kinds of AdminCheckers there are and how central
admin-checking is to your code. If there’s no normal default for the
admin_checker value, and if you really can’t make a DataFetcher without knowing
what kind of checking policies it’ll be working with, you should probably inject
your admin_checker in the constructor, marking it as an important Dependency.

### HttpRequestService

There’s one other facet to my HttpRequest object that I thought Practicing Ruby
readers might find interesting. Because Typhoeus is concurrent, you have to
queue up requests onto a shared Typhoeus::Hydra object. The requests don’t run
until you invoke the hydra’s #run method. I experimented with storing the Hydra
object in various places and ended up creating a factory for HttpRequest objects
called HttpRequestService, below. Can you spot the dependencies and adjustments?
It doesn’t have notifications, but I could see adding some instrumentation to
measure HttpRequest times.

```ruby
require "typhoeus"
require_relative "http_request"

class HttpRequestService
  attr_writer :hydra

  def request(url,options = {})
    HttpRequest.new(url,options).tap do |http_request|
      hydra.queue(http_request.typhoeus_request)
    end
  end

  def run
    hydra.run
  end

  private

  def hydra
    @hydra ||= Typhoeus::Hydra.new
  end
end
```

Instances of the HttpRequestService end up as Adjustment peers for the objects
responsible for fetching data.

### Dependency Injection Containers

Rubyists generally eschew [dependency injection containers][di] but they complement
the DNA style quite well. I use dependency injection containers as the single
place where my code can pull in dependencies from different sources. These
dependencies sometimes involve extra setup steps or massaging, depending on
whether the code is running in production mode or not, and the container is a
convenient place to consolidate that kind of housekeeping code.  It often
provides the sensible default for notifications and adjustments, and it’s an
important part of the boot process for most of my Ruby code.

I’ve created a simple gem for this purpose called [dim][dim] based on [Jim Weirich’s
article][jw-di]. If you’re interested in the topic, I highly recommend that article.
Here’s a snippet of one of my container definitions:


```ruby
require "dim"
AppContainer = Dim::Container.new

AppContainer.register(:env) { ENV['ADWORK_ENV'] || "development" }
AppContainer.register(:production?) { |c| c.env == 'production' }
AppContainer.register(:development?) { |c| c.env == 'development' }
AppContainer.register(:test?) { |c| c.env == 'test' }
AppContainer.register(:root) { File.expand_path(File.dirname(__FILE__)+"/../..") }

AppContainer.register(:logger) do |c|
  if c.test?
    Logger.new("#{c.root}/log/#{c.env}.log")
  elsif c.production?
    Sidekiq.logger.tap do |l| 
      l.level = ENV["DEBUG"].present? ? Logger::DEBUG : Logger::INFO 
    end
  else
    Logger.new(STDOUT)
  end
end

AppContainer.register(:mechanize) do |c|
  Mechanize.new do |agent|
    agent.log = c.logger
    agent.user_agent_alias = "Mac Safari"
    agent.keep_alive = false
  end
end

AppContainer.register(:salesforce_client) do |c|
  require "databasedotcom"
  Databasedotcom::Client.new(client_id: c.salesforce_consumer_key, 
                             client_secret: c.salesforce_consumer_secret)
end
```

### Conclusion

Don’t hold too rigidly to these classifications; they’re more like heuristics.
As Steve Freeman and Nat Pryce wrote:

> What matters most is the context in which the collaborating objects are used.
> For example, in one application an auditing log could be a dependency, because
> auditing is a legal requirement for the business and no object should be created
> without an audit trail. Elsewhere, it could be a notification, because auditing
> is a user choice and objects will function perfectly well without it.

When considering how to organize object peers I recommend you favor what’s most
understandable and flexible, even if it means deviating from the DNA pattern.

[strategy]: http://en.wikipedia.org/wiki/Strategy_pattern
[GOOS]: http://www.growing-object-oriented-software.com/
[2-14]: http://practicingruby.com/articles/14
[di]: http://martinfowler.com/articles/injection.html
[dim]: https://github.com/subelsky/dim
[jw-di]: http://onestepback.org/index.cgi/Tech/Ruby/DependencyInjectionInRuby.rdoc
