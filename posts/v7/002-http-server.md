*This article was written by Luke Francl, a Ruby developer living in
San Francisco. He is a developer at [Swiftype](https://swiftype.com) where he
works on everything from web crawling to answering support requests.*

Implementing a simpler version of a technology that you use every day can
help you understand it better. In this article, we will apply this
technique by building a simple HTTP server in Ruby.

By the time you're done reading, you will know how to serve files from your
computer to a web browser with no dependencies other than a few standard
libraries that ship with Ruby. Although the server
we build will not be robust or anywhere near feature complete,
it will allow you to look under the hood of one of the most fundamental
pieces of technology that we all use on a regular basis.

## A (very) brief introduction to HTTP

We all use web applications daily and many of us build
them for a living, but much of our work is done far above the HTTP level.
We'll need come down from the clouds a bit in order to explore
what happens at the protocol level when someone clicks a 
link to *http://example.com/file.txt* in their web browser. 

The following steps roughly cover the typical HTTP request/response lifecycle:

1) The browser issues an HTTP request by opening a TCP socket connection to
`example.com` on port 80. The server accepts the connection, opening a
socket for bi-directional communication.

2) When the connection has been made, the HTTP client sends a HTTP request:

```
GET /file.txt HTTP/1.1
User-Agent: ExampleBrowser/1.0
Host: example.com
Accept: */*
```

3) The server then parses the request. The first line is the Request-Line which contains
the HTTP method (`GET`), Request-URI (`/file.txt`), and HTTP version (`1.1`).
Subsequent lines are headers, which consists of key-value pairs delimited by `:`. 
After the headers is a blank line followed by an optional message body (not shown in
this example).

4) Using the same connection, the server responds with the contents of the file:

```
HTTP/1.1 200 OK
Content-Type: text/plain
Content-Length: 13
Connection: close

hello world
```

5) After finishing the response, the server closes the socket to terminate the connection.

The basic workflow shown above is one of HTTP's most simple use cases,
but it is also one of the most common interactions handled by web servers.
Let's jump right into implementing it!

## Writing the "Hello World" HTTP server

To begin, let's build the simplest thing that could possibly work: a web server
that always responds "Hello World" with HTTP 200 to any request. The following
code mostly follows the process outlined in the previous section, but is
commented line-by-line to help you understand its implementation details:

```ruby
require 'socket' # Provides TCPServer and TCPSocket classes

# Initialize a TCPServer object that will listen
# on localhost:2345 for incoming connections.
server = TCPServer.new('localhost', 2345)

# loop infinitely, processing one incoming
# connection at a time.
loop do

  # Wait until a client connects, then return a TCPSocket
  # that can be used in a similar fashion to other Ruby
  # I/O objects. (In fact, TCPSocket is a subclass of IO.)
  socket = server.accept

  # Read the first line of the request (the Request-Line)
  request = socket.gets

  # Log the request to the console for debugging
  STDERR.puts request

  response = "Hello World!\n"

  # We need to include the Content-Type and Content-Length headers
  # to let the client know the size and type of data
  # contained in the response. Note that HTTP is whitespace
  # sensitive, and expects each header line to end with CRLF (i.e. "\r\n")
  socket.print "HTTP/1.1 200 OK\r\n" +
               "Content-Type: text/plain\r\n" +
               "Content-Length: #{response.bytesize}\r\n" +
               "Connection: close\r\n"

  # Print a blank line to separate the header from the response body,
  # as required by the protocol.
  socket.print "\r\n"

  # Print the actual response body, which is just "Hello World!\n"
  socket.print response

  # Close the socket, terminating the connection
  socket.close
end
```
To test your server, run this code and then try opening `http://localhost:2345/anything`
in a browser. You should see the "Hello world!" message. Meanwhile, in the output for
the HTTP server, you should see the request being logged:

```
GET /anything HTTP/1.1
```

Next, open another shell and test it with `curl`:

```
curl --verbose -XGET http://localhost:2345/anything
```

You'll see the detailed request and response headers:

```
* About to connect() to localhost port 2345 (#0)
*   Trying 127.0.0.1... connected
* Connected to localhost (127.0.0.1) port 2345 (#0)
> GET /anything HTTP/1.1
> User-Agent: curl/7.19.7 (universal-apple-darwin10.0) libcurl/7.19.7
              OpenSSL/0.9.8r zlib/1.2.3
> Host: localhost:2345
> Accept: */*
>
< HTTP/1.1 200 OK
< Content-Type: text/plain
< Content-Length: 13
< Connection: close
<
Hello world!
* Closing connection #0
```

Congratulations, you've written a simple HTTP server! Now we'll 
build a more useful one.

## Serving files over HTTP

We're about to build a more realistic program that is capable of 
serving files over HTTP, rather than simply responding to any request
with "Hello World". In order to do that, we'll need to make a few 
changes to the way our server works.

For each incoming request, we'll parse the `Request-URI` header and translate it into
a path to a file within the server's public folder. If we're able to find a match, we'll
respond with its contents, using the file's size to determine the `Content-Length`,
and its extension to determine the `Content-Type`. If no matching file can be found,
we'll respond with a `404 Not Found` error status.

Most of these changes are fairly straightforward to implement, but mapping the
`Request-URI` to a path on the server's filesystem is a bit more complicated due
to security issues. To simplify things a bit, let's assume for the moment that a
`requested_file` function has been implemented for us already that can handle
this task safely. Then we could build a rudimentary HTTP file server in the following way:

```ruby
require 'socket'
require 'uri'

# Files will be served from this directory
WEB_ROOT = './public'

# Map extensions to their content type
CONTENT_TYPE_MAPPING = {
  'html' => 'text/html',
  'txt' => 'text/plain',
  'png' => 'image/png',
  'jpg' => 'image/jpeg'
}

# Treat as binary data if content type cannot be found
DEFAULT_CONTENT_TYPE = 'application/octet-stream'

# This helper function parses the extension of the
# requested file and then looks up its content type.

def content_type(path)
  ext = File.extname(path).split(".").last
  CONTENT_TYPE_MAPPING.fetch(ext, DEFAULT_CONTENT_TYPE)
end

# This helper function parses the Request-Line and
# generates a path to a file on the server.

def requested_file(request_line)
  # ... implementation details to be discussed later ...
end

# Except where noted below, the general approach of
# handling requests and generating responses is
# similar to that of the "Hello World" example
# shown earlier.

server = TCPServer.new('localhost', 2345)

loop do
  socket       = server.accept
  request_line = socket.gets

  STDERR.puts request_line

  path = requested_file(request_line)

  # Make sure the file exists and is not a directory
  # before attempting to open it.
  if File.exist?(path) && !File.directory?(path)
    File.open(path, "rb") do |file|
      socket.print "HTTP/1.1 200 OK\r\n" +
                   "Content-Type: #{content_type(file)}\r\n" +
                   "Content-Length: #{file.size}\r\n" +
                   "Connection: close\r\n"

      socket.print "\r\n"

      # write the contents of the file to the socket
      IO.copy_stream(file, socket)
    end
  else
    message = "File not found\n"

    # respond with a 404 error code to indicate the file does not exist
    socket.print "HTTP/1.1 404 Not Found\r\n" +
                 "Content-Type: text/plain\r\n" +
                 "Content-Length: #{message.size}\r\n" +
                 "Connection: close\r\n"

    socket.print "\r\n"

    socket.print message
  end

  socket.close
end
```

Although there is a lot more code here than what we saw in the
"Hello World" example, most of it is routine file manipulation
similar to the kind we'd encounter in everyday code. Now there
is only one more feature left to implement before we can serve
files over HTTP: the `requested_file` method.

## Safely converting a URI into a file path

Practically speaking, mapping the Request-Line to a file on the 
server's filesystem is easy: you extract the Request-URI, scrub 
out any parameters and URI-encoding, and then finally turn that 
into a path to a file in the server's public folder:

```ruby
# Takes a request line (e.g. "GET /path?foo=bar HTTP/1.1")
# and extracts the path from it, scrubbing out parameters
# and unescaping URI-encoding.
#
# This cleaned up path (e.g. "/path") is then converted into
# a relative path to a file in the server's public folder
# by joining it with the WEB_ROOT.
def requested_file(request_line)
  request_uri  = request_line.split(" ")[1]
  path         = URI.unescape(URI(request_uri).path)

  File.join(WEB_ROOT, path)
end
```

However, this implementation has a very bad security problem that has affected
many, many web servers and CGI scripts over the years: the server will happily
serve up any file, even if it's outside the `WEB_ROOT`.

Consider a request like this:

```
GET /../../../../etc/passwd HTTP/1.1
```

On my system, when `File.join` is called on this path, the ".." path components
will cause it escape the `WEB_ROOT` directory and serve the `/etc/passwd` file.
Yikes! We'll need to sanitize the path before use in order to prevent this
kind of problem.

> **Note:** If you want to try to reproduce this issue on your own machine,
you may need to use a low level tool like *curl* to demonstrate it. Some browsers change the path to remove the ".." before sending a request to the server.

Because security code is notoriously difficult to get right, we will borrow our
implementation from [Rack::File](https://github.com/rack/rack/blob/master/lib/rack/file.rb).
The approach shown below was actually added to `Rack::File` in response to a [similar
security vulnerability](http://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2013-0262) that
was disclosed in early 2013:

```ruby
def requested_file(request_line)
  request_uri  = request_line.split(" ")[1]
  path         = URI.unescape(URI(request_uri).path)

  clean = []

  # Split the path into components
  parts = path.split("/")

  parts.each do |part|
    # skip any empty or current directory (".") path components
    next if part.empty? || part == '.'
    # If the path component goes up one directory level (".."),
    # remove the last clean component.
    # Otherwise, add the component to the Array of clean components
    part == '..' ? clean.pop : clean << part
  end

  # return the web root joined to the clean path
  File.join(WEB_ROOT, *clean)
end
```

To test this implementation (and finally see your file server in action), 
replace the `requested_file` stub in the example from the previous section 
with the implementation shown above, and then create an `index.html` file 
in a `public/` folder that is contained within the same directory as your
server script. Upon running the script, you should be able to 
visit `http://localhost:2345/index.html` but NOT be able to reach any
files outside of the `public/` folder.

## Serving up index.html implicitly

If you visit `http://localhost:2345` in your web browser, you'll see a 404 Not
Found response, even though you've created an index.html file. Most real web
servers will serve an index file when the client requests a directory. Let's
implement that.

This change is more simple than it seems, and can be accomplished by adding
a single line of code to our server script:

```diff
# ...
path = requested_file(request_line)

+ path = File.join(path, 'index.html') if File.directory?(path)

if File.exist?(path) && !File.directory?(path)
# ...
```

Doing so will cause any path that refers to a directory to have "/index.html" appended to
the end of it. This way, `/` becomes `/index.html`, and `/path/to/dir` becomes
`path/to/dir/index.html`.

Perhaps surprisingly, the validations in our response code do not need
to be changed. Let's recall what they look like and then examine why
that's the case:

```ruby
if File.exist?(path) && !File.directory?(path)
  # serve up the file...
else
  # respond with a 404
end
```

Suppose a request is received for `/somedir`. That request will automatically be converted by our server into `/somedir/index.html`. If the index.html exists within `/somedir`, then it will be served up without any problems. However, if `/somedir` does not contain an `index.html` file, the `File.exist?` check will fail, causing the server to respond with a 404 error code. This is exactly what we want!

It may be tempting to think that this small change would make it possible to remove the `File.directory?` check, and in normal circumstances you might be able to safely do with it. However, because leaving it in prevents an error condition in the edge case where someone attempts to serve up a directory named `index.html`, we've decided to leave that validation as it is.

With this small improvement, our file server is now pretty much working as we'd expect it to. If you want to play with it some more, you can grab the [complete source code](https://github.com/elm-city-craftworks/practicing-ruby-examples/tree/master/v7/002) from GitHub.

## Where to go from here

In this article, we reviewed how HTTP works, then built a simple web
server that can serve up files from a directory. We've also examined
one of the most common security problems with web applications and
fixed it. If you've made it this far, congratulations! That's a lot
to learn in one day.

However, it's obvious that the server we've built is extremely limited.
If you want to continue in your studies, here are a few recommendations
for how to go about improving the server:

* According to the HTTP 1.1 specification, a server must minimally
respond to GET and HEAD to be compliant. Implement the HEAD response.
* Add error handling that returns a 500 response to the client
if something goes wrong with the request.
* Make the web root directory and port configurable.
* Add support for POST requests. You could implement CGI by executing
a script when it matches the path, or implement 
the [Rack spec](http://rack.rubyforge.org/doc/SPEC.html) to
let the server serve Rack apps with `call`.
* Reimplement the request loop using [GServer](http://www.ruby-doc.org/stdlib-2.0/libdoc/gserver/rdoc/GServer.html)
(Ruby's generic threaded server) to handle multiple connections.

Please do share your experiences and code if you decide to try any of
these ideas, or if you come up with some improvement ideas of your own.
Happy hacking!

*We'd like to thank Eric Hodel, Magnus Holm, Piotr Szotkowski, and 
Mathias Lafeldt for reviewing this article and providing feedback 
before we published it.*

*This article was written by Aaron Patterson, a Ruby
developer living in Seattle, WA.  He's been having fun writing Ruby for the past
7 years, and hopes to share his love of Ruby with you.*

Hey everybody!  I hope you're having a great day today!  The sun has peeked out
of the clouds for a bit today, so I'm doing great!

In this article, we're going to be looking at some compiler tools for use with Ruby.  In
order to explore these tools, we'll write a JSON parser.  I know you're saying,
"but Aaron, *why* write a JSON parser?  Don't we have like 1,234,567 of them?".
Yes!  We do have precisely 1,234,567 JSON parsers available in Ruby!  We're
going to parse JSON because the grammar is simple enough that we can finish the
parser in one sitting, and because the grammar is complex enough that we can
exercise some of Ruby's compiler tools.

As you read on, keep in mind that this isn't an article about parsing JSON, 
its an article about using parser and compiler tools in Ruby.

## The Tools We'll Be Using

I'm going to be testing this with Ruby 1.9.3, but it should work under any
flavor of Ruby you wish to try.  Mainly, we will be using a tool called `Racc`,
and a tool called `StringScanner`.

**Racc**

We'll be using Racc to generate our parser.  Racc is an LALR parser generator
similar to YACC.  YACC stands for "Yet Another Compiler Compiler", but this is
the Ruby version, hence "Racc".  Racc converts a grammar file (the ".y" file)
to a Ruby file that contains state transitions.  These state transitions are
interpreted by the Racc state machine (or runtime).  The Racc runtime ships
with Ruby, but the tool that converts the ".y" files to state tables does not.
In order to install the converter, do `gem install racc`.

We will write ".y" files, but users cannot run the ".y" files.  First we convert
them to runnable Ruby code, and ship the runnable Ruby code in our gem.  In
practical terms, this means that *only we install the Racc gem*, other users
do not need it.

Don't worry if this doesn't make sense right now.  It will become more clear
when we get our hands dirty and start playing with code.

**StringScanner**

Just like the name implies, [StringScanner](http://ruby-doc.org/stdlib-1.9.3/libdoc/strscan/rdoc/StringScanner.html)
is a class that helps us scan strings.  It keeps track of where we are
in the string, and lets us advance forward via regular expressions or by
character.

Let's try it out!  First we'll create a `StringScanner` object, then we'll scan
some letters from it:

```ruby
irb(main):001:0> require 'strscan'
=> true
irb(main):002:0> ss = StringScanner.new 'aabbbbb'
=> #<StringScanner 0/7 @ "aabbb...">
irb(main):003:0> ss.scan /a/
=> "a"
irb(main):004:0> ss.scan /a/
=> "a"
irb(main):005:0> ss.scan /a/
=> nil
irb(main):006:0> ss
=> #<StringScanner 2/7 "aa" @ "bbbbb">
irb(main):007:0>
```

Notice that the third call to
[StringScanner#scan](http://ruby-doc.org/stdlib-1.9.3/libdoc/strscan/rdoc/StringScanner.html#method-i-scan)
resulted in a `nil`, since the regular expression did not match from the current
position.  Also note that when you inspect the `StringScanner` instance, you can
see the position of the scanner (in this case `2/7`).

We can also move through the scanner character by character using
[StringScanner#getch](http://ruby-doc.org/stdlib-1.9.3/libdoc/strscan/rdoc/StringScanner.html#method-i-getch):

```ruby
irb(main):006:0> ss
=> #<StringScanner 2/7 "aa" @ "bbbbb">
irb(main):007:0> ss.getch
=> "b"
irb(main):008:0> ss
=> #<StringScanner 3/7 "aab" @ "bbbb">
irb(main):009:0>
```

The `getch` method returns the next character, and advances the pointer by one.

Now that we've covered the basics for scanning strings, let's take a 
look at using Racc.

## Racc Basics

As I said earlier, Racc is an LALR parser generator.  You can think of it as a
system that lets you write limited regular expressions that can execute
arbitrary code at different points as they're being evaluated.

Let's look at an example.  Suppose we have a pattern we want to match:
`(a|c)*abb`.  That is, we want to match any number of 'a' or 'c' followed by
'abb'.  To translate this to a Racc grammar, we try to break up this regular
expression to smaller parts, and assemble them as the whole.  Each part is
called a "production".  Let's try breaking up this regular expression so that we
can see what the productions look like, and the format of a Racc grammar file.

First we create our grammar file.  At the top of the file, we declare the Ruby
class to be produced, followed by the `rule` keyword to indicate that we're
going to declare the productions, followed by the `end` keyword to indicate the
end of the productions:

```
class Parser
rule
end
```

Next lets add the production for "a|c".  We'll call this production `a_or_c`:


```
class Parser
rule
  a_or_c : 'a' | 'c' ;
end
```

Now we have a rule named `a_or_c`, and it matches the characters 'a' or 'c'.  In
order to match one or more `a_or_c` productions, we'll add a recursive
production called `a_or_cs`:

```
class Parser
rule
  a_or_cs
    : a_or_cs a_or_c
    | a_or_c
    ;
  a_or_c : 'a' | 'c' ;
end
```

The `a_or_cs` production recurses on itself, equivalent to the regular
expression `(a|c)+`.  Next, a production for 'abb':

```
class Parser
rule
  string
    | a_or_cs abb
    | abb         
    ;
  a_or_cs
    : a_or_cs a_or_c
    | a_or_c
    ;
  a_or_c : 'a' | 'c' ;
  abb    : 'a' 'b' 'b' 
end
```

Finally, the `string` production ties everything together:


```
class Parser
rule
  string
    : a_or_cs abb
    | abb
    ;
  a_or_cs
    : a_or_cs a_or_c
    | a_or_c
    ;
  a_or_c : 'a' | 'c' ;
  abb    : 'a' 'b' 'b';
end
```

This final production matches one or more 'a' or 'c' characters followed by
'abb', or just the string 'abb' on its own.  This is equivalent to our original
regular expression of `(a|c)*abb`.

**But Aaron, this is so long!**

I know, it's much longer than the regular expression version.  However, we can
add arbitrary Ruby code to be executed at any point in the matching process.
For example, every time we find just the string "abb", we can execute some
arbitrary code:

```
class Parser
rule
  string
    | a_or_cs abb
    | abb         
    ;
  a_or_cs
    : a_or_cs a_or_c
    | a_or_c
    ;
  a_or_c : 'a' | 'c' ;
  abb    : 'a' 'b' 'b' { puts "I found abb!" };
end
```

The Ruby code we want to execute should be wrapped in curly braces and placed
after the rule where we want the trigger to fire.

To use this parser, we also need a tokenizer that can break the input
data into tokens, along with some other boilerplate code. If you are curious
about how that works, you can check out [this standalone
example](https://gist.githubusercontent.com/sandal/9532497/raw/8e3bb03fc24c8f6604f96516bf242e7e13d0f4eb/parser_example.y).

Now that we've covered the basics, we can use knowledge we have so far to build 
an event based JSON parser and tokenizer.

## Building our JSON Parser

Our JSON parser is going to consist of three different objects, a parser, a
tokenizer, and document handler.The parser will be written with a Racc grammar, 
and will ask the tokenizer for input from the input stream.  Whenever the parser 
can identify a part of the JSON stream, it will send an event to the document 
handler.  The document handler is responsible for collecting the JSON 
information and translating it to a Ruby data structure. When we read in 
a JSON document, the following method calls are made:

![method calls](http://i.imgur.com/HZ0Sa.png)

It's time to get started building this system. We'll focus on building the 
tokenizer first, then work on the grammar for the parser, and finally implement 
the document handler.

## Building the tokenizer

Our tokenizer is going to be constructed with an IO object.  We'll read the
JSON data from the IO object.  Every time `next_token` is called, the tokenizer
will read a token from the input and return it. Our tokenizer will return the 
following tokens, which we derived from the [JSON spec](http://www.json.org/):

* Strings
* Numbers
* True
* False
* Null

Complex types like arrays and objects will be determined by the parser.

**`next_token` return values:**

When the parser calls `next_token` on the tokenizer, it expects a two element
array or a `nil` to be returned.  The first element of the array must contain
the name of the token, and the second element can be anything (but most people
just add the matched text).  When a `nil` is returned, that indicates there are
no more tokens left in the tokenizer.

**`Tokenizer` class definition:**

Let's look at the source for the Tokenizer class and walk through it:

```ruby
module RJSON
  class Tokenizer
    STRING = /"(?:[^"\\]|\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4}))*"/
    NUMBER = /-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/
    TRUE   = /true/
    FALSE  = /false/
    NULL   = /null/

    def initialize io
      @ss = StringScanner.new io.read
    end

    def next_token
      return if @ss.eos?

      case
      when text = @ss.scan(STRING) then [:STRING, text]
      when text = @ss.scan(NUMBER) then [:NUMBER, text]
      when text = @ss.scan(TRUE)   then [:TRUE, text]
      when text = @ss.scan(FALSE)  then [:FALSE, text]
      when text = @ss.scan(NULL)   then [:NULL, text]
      else
        x = @ss.getch
        [x, x]
      end
    end
  end
end
```

First we declare some regular expressions that we'll use along with the string
scanner.  These regular expressions were derived from the definitions on
[json.org](http://www.json.org).  We instantiate a string scanner object in the
constructor.  String scanner requires a string on construction, so we read the
IO object.  However, we could build an alternative tokenizer that reads from the
IO as needed.

The real work is done in the `next_token` method.  The `next_token` method
returns nil if there is nothing left to read from the string scanner, then it
tries each regular expression until it finds a match.  If it finds a match, it
returns the name of the token (for example `:STRING`) along with the text that
it matched.  If none of the regular expressions match, then we read one
character off the scanner, and return that character as both the name of the
token, and the value.

Let's try feeding the tokenizer a JSON string and see what tokens come out:

```
irb(main):003:0> tok = RJSON::Tokenizer.new StringIO.new '{"foo":null}'
=> #<RJSON::Tokenizer:0x007fa8529fbeb8 @ss=#<StringScanner 0/12 @ "{\"foo...">>
irb(main):004:0> tok.next_token
=> ["{", "{"]
irb(main):005:0> tok.next_token
=> [:STRING, "\"foo\""]
irb(main):006:0> tok.next_token
=> [":", ":"]
irb(main):007:0> tok.next_token
=> [:NULL, "null"]
irb(main):008:0> tok.next_token
=> ["}", "}"]
irb(main):009:0> tok.next_token
=> nil
```

In this example, we wrap the JSON string with a `StringIO` object in order to
make the string quack like an IO.  Next, we try reading tokens from the
tokenizer.  Each token the Tokenizer understands has the name as the first value of
the array, where the unknown tokens have the single character value.  For
example, string tokens look like this: `[:STRING, "foo"]`, and unknown tokens
look like this: `['(', '(']`.   Finally, `nil` is returned when the input has
been exhausted.

This is it for our tokenizer.  The tokenizer is initialized with an `IO` object, 
and has only one method: `next_token`.  Now we can focus on the parser side.

## Building the parser

We have our tokenizer in place, so now it's time to assemble the parser.  First
we need to do a little house keeping.  We're going to generate a Ruby file from
our `.y` file.  The Ruby file needs to be regenerated every time the `.y` file
changes.  A Rake task sounds like the perfect solution.

**Defining a compile task:**

The first thing we'll add to the Rakefile is a rule that says *"translate .y files to
.rb files using the following command"*:

```ruby
rule '.rb' => '.y' do |t|
  sh "racc -l -o #{t.name} #{t.source}"
end
```

Then we'll add a "compile" task that depends on the generated `parser.rb` file:

```ruby
task :compile => 'lib/rjson/parser.rb'
```

We keep our grammar file as `lib/rjson/parser.y`, and when we run `rake
compile`, rake will automatically translate the `.y` file to a `.rb` file using
Racc.

Finally we make the test task depend on the compile task so that when we run
`rake test`, the compiled file is automatically generated:

```ruby
task :test => :compile
```

Now we can compile and test the `.y` file.

**Translating the JSON.org spec:**

We're going to translate the diagrams from [json.org](http://www.json.org/) to a
Racc grammar.  A JSON document should be an object or an array at the root, so
we'll make a production called `document` and it should be an `object` or an
`array`:

```
rule
  document
    : object
    | array
    ;
```

Next we need to define `array`.  The `array` production can either be empty, or
contain 1 or more values:

```
  array
    : '[' ']'
    | '[' values ']'
    ;
```

The `values` production can be recursively defined as one value, or many values
separated by a comma:

```
  values
    : values ',' value
    | value
    ;
```

The JSON spec defines a `value` as a string, number, object, array, true, false,
or null.  We'll define it the same way, but for the immediate values such as
NUMBER, TRUE, and FALSE, we'll use the token names we defined in the tokenizer:

```
  value
    : string
    | NUMBER
    | object
    | array
    | TRUE
    | FALSE
    | NULL
    ;
```

Now we need to define the `object` production.  Objects can be empty, or
have many pairs:

```
  object
    : '{' '}'
    | '{' pairs '}'
    ;
```

We can have one or more pairs, and they must be separated with a comma.  We can
define this recursively like we did with the array values:

```
  pairs
    : pairs ',' pair
    | pair
    ;
```

Finally, a pair is a string and value separated by a colon:

```
  pair
    : string ':' value
    ;
```

Now we let Racc know about our special tokens by declaring them at the top, and
we have our full parser:

```
class RJSON::Parser
token STRING NUMBER TRUE FALSE NULL
rule
  document
    : object
    | array
    ;
  object
    : '{' '}'
    | '{' pairs '}'
    ;
  pairs
    : pairs ',' pair
    | pair
    ;
  pair : string ':' value ;
  array
    : '[' ']'
    | '[' values ']'
    ;
  values
    : values ',' value
    | value
    ;
  value
    : string
    | NUMBER
    | object
    | array
    | TRUE
    | FALSE
    | NULL
    ;
  string : STRING ;
end
```

## Building the handler

Our parser will send events to a document handler.  The document handler will
assemble the beautiful JSON bits in to lovely Ruby object!  Granularity of the
events is really up to you, but I'm going to go with 5 events:

* `start_object` - called when an object is started
* `end_object`   - called when an object ends
* `start_array`  - called when an array is started
* `end_array`    - called when an array ends
* `scalar`       - called with terminal values like strings, true, false, etc

With these 5 events, we can assemble a Ruby object that represents the JSON
object we are parsing.

**Keeping track of events**

The handler we build will simply keep track of events sent to us by the parser.
This creates tree-like data structure that we'll use to convert JSON to Ruby.

```ruby
module RJSON
  class Handler
    def initialize
      @stack = [[:root]]
    end

    def start_object
      push [:hash]
    end

    def start_array
      push [:array]
    end

    def end_array
      @stack.pop
    end
    alias :end_object :end_array

    def scalar(s)
      @stack.last << [:scalar, s]
    end

    private

    def push(o)
      @stack.last << o
      @stack << o
    end
  end
end
```

When the parser encounters the start of an object, the handler pushes a list on
the stack with the "hash" symbol to indicate the start of a hash.  Events that
are children will be added to the parent, then when the object end is
encountered the parent is popped off the stack.

This may be a little hard to understand, so let's look at some examples.  If we
parse this JSON: `{"foo":{"bar":null}}`, then the `@stack` variable will look
like this:

```ruby
[[:root,
  [:hash,
    [:scalar, "foo"],
    [:hash,
      [:scalar, "bar"],
      [:scalar, nil]]]]]
```

If we parse a JSON array, like this JSON: `["foo",null,true]`, the `@stack`
variable will look like this:

```ruby
[[:root,
  [:array,
    [:scalar, "foo"],
    [:scalar, nil],
    [:scalar, true]]]]
```

**Converting to Ruby:**

Now that we have an intermediate representation of the JSON, let's convert it to
a Ruby data structure.  To convert to a Ruby data structure, we can just write a
recursive function to process the tree:

```ruby
def result
  root = @stack.first.last
  process root.first, root.drop(1)
end

private
def process type, rest
  case type
  when :array
    rest.map { |x| process(x.first, x.drop(1)) }
  when :hash
    Hash[rest.map { |x|
      process(x.first, x.drop(1))
    }.each_slice(2).to_a]
  when :scalar
    rest.first
  end
end
```

The `result` method removes the `root` node and sends the rest to the `process`
method.  When the `process` method encounters a `hash` symbol it builds a hash
using the children by recursively calling `process`.  Similarly, when an
`array` symbol is found, an array is constructed recursively with the children.
Scalar values are simply returned (which prevents an infinite loop).  Now if we
call `result` on our handler, we can get the Ruby object back.

Let's see it in action:

```ruby
require 'rjson'

input   = StringIO.new '{"foo":"bar"}'
tok     = RJSON::Tokenizer.new input
parser  = RJSON::Parser.new tok
handler = parser.parse
handler.result # => {"foo"=>"bar"}
```

**Cleaning up the RJSON API:**

We have a fully function JSON parser.  Unfortunately, the API is not very
friendly.  Let's take the previous example, and package it up in a method:

```ruby
module RJSON
  def self.load(json)
    input   = StringIO.new json
    tok     = RJSON::Tokenizer.new input
    parser  = RJSON::Parser.new tok
    handler = parser.parse
    handler.result
  end
end
```

Since we built our JSON parser to deal with IO from the start, we can add
another method for people who would like to pass a socket or file handle:

```ruby
module RJSON
  def self.load_io(input)
    tok     = RJSON::Tokenizer.new input
    parser  = RJSON::Parser.new tok
    handler = parser.parse
    handler.result
  end

  def self.load(json)
    load_io StringIO.new json
  end
end
```

Now the interface is a bit more friendly:

```ruby
require 'rjson'
require 'open-uri'

RJSON.load '{"foo":"bar"}' # => {"foo"=>"bar"}
RJSON.load_io open('http://example.org/some_endpoint.json')
```

## Reflections 

So we've finished our JSON parser.  Along the way we've studied compiler
technology including the basics of parsers, tokenizers, and even interpreters
(yes, we actually interpreted our JSON!).  You should be proud of yourself!

The JSON parser we've built is versatile. We can:

* Use it in an event driven manner by implementing a Handler object
* Use a simpler API and just feed strings
* Stream in JSON via IO objects

I hope this article has given you the confidence to start playing with parser
and compiler technology in Ruby. Please leave a comment if you have any
questions for me.

## Post Script

I want to follow up with a few bits of minutiae that I omitted to maintain
clarity in the article:

* [Here](https://github.com/tenderlove/rjson/blob/master/lib/rjson/parser.y) is
the final grammar file for our JSON parser.  Notice 
the [---- inner section in the .y file](https://github.com/tenderlove/rjson/blob/master/lib/rjson/parser.y#L53).
Anything in that section is included *inside* the generated parser class.  This
is how we get the handler object to be passed to the parser.

* Our parser actually [does the
translation](https://github.com/tenderlove/rjson/blob/master/lib/rjson/parser.y#L42-50)
of JSON terminal nodes to Ruby.  So we're actually doing the translation of JSON
to Ruby in two places: the parser *and* the document handler.  The document
handler deals with structure where the parser deals with immediate values (like
true, false, etc).  An argument could be made that none or all of this
translation *should* be done in the parser.

* Finally, I mentioned that [the
tokenizer](https://github.com/tenderlove/rjson/blob/master/lib/rjson/tokenizer.rb)
buffers.  I implemented a simple non-buffering tokenizer that you can read
[here](https://github.com/tenderlove/rjson/blob/master/lib/rjson/stream_tokenizer.rb).
It's pretty messy, but I think could be cleaned up by using a state machine.

That's all. Thanks for reading! <3 <3 <3

*We'd like to thank Eric Hodel, Magnus Holm, Piotr Szotkowski, and 
Mathias Lafeldt for reviewing this article and providing feedback 
before we published it.*


> NOTE: If you'd like to learn more about this topic, consider doing the Practicing Ruby self-guided course on [Streams, Files, and Sockets](https://practicingruby.com/articles/study-guide-1?u=dc2ab0f9bb). You've already completed one of its reading exercises by working through this article!
