## Problem

*My methods are painful to use -- they have too many arguments!*

The more arguments a method accepts, the harder it is to remember its 
interface. Also, bloated method contracts can easily lead to brittle code that 
is easily broken by small changes.

Suppose we were building a HTTP client library called `HyperClient`. A trivial
request might look like this:

```ruby
http = HyperClient.new("example.com")
http.get("/")
```

However, we may also want to support a few other features, such as 
accessing HTTP services running on non-standard ports, or routing 
requests through a proxy. If we simply add these features in
without giving careful thought to the design, we may end up
with the following bloated interface for `HyperClient.new`: 

```ruby
http = HyperClient.new("example.com", 1337, 
                       "internal.proxy.example.com", 8080, 
                       "myuser", "mypassword")
```

If the above code looks familiar to you, it's because it is modeled directly
after how Ruby's `Net::HTTP` standard library works. Since that library is most
commonly used as an anti-pattern when it comes to API design, it serves as a
fitting example for what *not* to do here.

There are lots of subtle reasons why this style of method interface is bad, but
three stand out as being immediately obvious:

* Remembering the correct positions for six arguments that don't have an obvious
natural order to them is not easy.

* Working with optional arguments is non-obvious, because it depends upon the use
of symbolic flags (i.e passing `nil` to instruct the client to use a default port)

* If underlying API changes and a new optional argument is introduced, it must 
either be added to the last position or risk breaking all callers that relied
on the previous order of the arguments.

Fortunately, all of the above points can be addressed by designing a better
method interface.

## Solution

*Use a combination of keyword arguments and parameter objects to
create interfaces that both more memorable and more maintainable.*

```ruby
proxy = HyperClient::Proxy.new(:address  =>  "internal.proxy.example.com",
                               :port     =>  8080,
                               :username => "myuser",
                               :password => "mypass")

http = HyperClient.new("example.com", 
                       :port  => 1337, :proxy => proxy) 
```

## Discussion

Both the original and improved code have the same default state

http = HyperClient.new("example.com")

Where they differ is when you have extra parameters. Dealing with
default values in the former is *much* uglier. For example, if
HyperClient provided default ports for both the service and the
proxy, you'd need to do something like this when using a username
and password:

```ruby
http = HyperClient.new("example.com", nil, 
                       "internal.proxy.example.com", nil,
                       "myuser", "mypassword")
```                       

In the improved code, those parameters could simply be omitted:

```ruby
proxy = HyperClient::Proxy.new(:address  =>  "internal.proxy.example.com",
                               :username => "myuser",
                               :password => "mypass")

http = HyperClient.new("example.com", :proxy => proxy)
```

### A common anti-pattern

A common idiom in Ruby is to have a single wide interface with many
keyword arguments, but this is bad form:


```ruby
http = HyperClient.new(:service_address => "google.com",
                       :service_port    => 80,
                       :proxy_address   => "internal.proxy.example.com",
                       :proxy_port      => 8080,
                       :proxy_username  => "myuser",
                       :proxy_password  => "mypass)
```

### (Possibly) going overboard

At the other extreme, we might find something like this:

```ruby
service = HyperClient::Service.new(:address => "example.com", 
                                   :port    => 1337)
                                    

http = HyperClient.new(:service => service,
                       :proxy   => proxy)
```
 
However, this degrades the 80% case, which isn't necessarily A Good Thing.


### Keyword arguments?
