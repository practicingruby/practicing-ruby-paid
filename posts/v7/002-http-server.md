# Writing a simple HTTP server in Ruby

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

We all use web applications on a daily basis and many of us build
them for a living, but much of our work is done far above the HTTP level. This
is a good thing when it comes to writing web applications, but when it comes to
building a web server, we're going to need to come down from the clouds a little
bit. 

What we need to understand is what actually happens at the protocol
level when someone clicks a link to `http://example.com/file.txt` in their
web browser. The following steps roughly outline that process:

1) The browser issues an HTTP request by opening a TCP socket connection to
`example.com` on port 80. The server accepts the connection and opens another
socket for bi-directional communication.

2) Once the connection has been made, the HTTP client sends the request over the
connection:

```
GET /file.txt HTTP/1.1
User-Agent: ExampleBrowser/1.0
Host: example.com
Accept: */*
```
    
3) The server then parses the request. The first line is the Request-Line which contains
the HTTP method (`GET`), Request-URI (`/file.txt`), and HTTP version (`1.1`).
Subsequent lines are headers, key-value pairs delimited by ":". After the
headers is a blank line followed by an optional message body (not used in
this example).

4) Using the same connection, the server responds with the contents of the file:

```
HTTP/1.1 200 OK
Content-Type: text/plain
Content-Length: 11

hello world
```

5) Finally, the server closes the socket after finishing the response to 
terminate the connection.

Using this basic workflow as a guide, we can start writing some code!

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
 
# loop infinitately, processing one incoming 
# connection at a time. 
loop do

  # Wait until a client connects, then return a TCPSocket
  # that can be used in a similar fashion to other Ruby
  # I/O objects. (In fact, TCPSocket is a subclass of IO)
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
               "Content-Length: #{response.size}\r\n" 
               
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
> User-Agent: curl/7.19.7 (universal-apple-darwin10.0) libcurl/7.19.7 OpenSSL/0.9.8r zlib/1.2.3
> Host: localhost:2345
> Accept: */*
> 
< HTTP/1.1 200 OK
< Content-Type: text/plain
< Content-Length: 13
< 
Hello world!
* Connection #0 to host localhost left intact
* Closing connection #0
```

Congratulations, you've written a simple HTTP server! Now we'll build a more useful one.

## Serving files over HTTP

We're about to build a more realistic program that is capable of serving files over HTTP, 
rather than simply responding to any request with "Hello World". In order to do that, we'll need
to make a few changes to the way our server works.

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

DEFAULT_CONTENT_TYPE = 'application/octet-stream'
CONTENT_TYPE_MAPPING = {
  'html' => 'text/html',
  'txt' => 'text/plain',
  'png' => 'image/png',
  'jpg' => 'image/jpeg'
}

def content_type(path)
  ext = File.extname(path).split(".").last
  CONTENT_TYPE_MAPPING[ext] || DEFAULT_CONTENT_TYPE
end

def requested_file(request_line)
  # implementation details to be discussed later
end

server = TCPServer.new('localhost', 2345)

loop do
  # Open a socket to communicate with the client
  socket = server.accept
  # Read the first line of the HTTP request
  request_line = socket.gets

  puts request_line

  path = requested_file(request_line)

  if File.exist?(path) && !File.directory?(path)
    file = File.new(path)

    socket.print "HTTP/1.1 200 OK\r\n"
    socket.print "Content-Type: #{content_type(file)}\r\n"
    socket.print "Content-Length: #{File.size(path)}\r\n"
    socket.print "\r\n"
    
    file.each do |line|
      socket.print line
    end
  else
    message = "File not found"
    
    socket.print "HTTP/1.1 404 Not Found\r\n"
    socket.print "Content-Type: text/plain\r\n"
    socket.print "Content-Length: #{message.size}\r\n"
    socket.print "\r\n"
    socket.print "#{message}\r\n"
  end

  socket.close
end

```

## Security

Practically speaking, mapping the Request-Line to a file on the server's filesystem is easy: you extract the Request-URI, scrub out any parameters and URI-encoding, and then finally turn that into a path to a file in the server's public folder:

```ruby
def requested_file(request_line)
  request_uri  = request_line.split(" ")[1]
  raw_path     = URI(request_uri).path

  File.join(WEB_ROOT, URI.unescape(raw_path))
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
Yikes! The `PATH_INFO` must be sanitized before use to prevent problems like
this. (Note: You may need to use `curl` to demonstrate this because browsers may
change the path to remove the ".." before sending it to the server.)

Since security code is notoriously difficult to get right, we will borrow some
from [`Rack::File`](https://github.com/rack/rack/blob/master/lib/rack/file.rb)
(In fact, this code was added to `Rack::File` [in response to a security
vulnerability](http://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2013-0262).),
a Rack application that serves files.

```ruby
def clean_path(path_info)
  clean = []
 
  # The path is URL-encoded, so it must be unescaped to translate it to a filesystem path
  path = URI.unescape(path_info)
 
  # Split the path into components
  parts = path.split("/")
  parts.each do |part|
    # skip any empty or current directory (".") path components
    next if part.empty? || part == '.'
    # If the path component goes up one directory level (".."), remove the last clean component
    # Otherwise, add the component to the Array of clean components
    part == '..' ? clean.pop : clean << part
  end
 
  # return the web root joined to the clean path 
  File.join(WEB_ROOT, *clean)
end
```

The `clean_path` method must be called before joining the path with the
`WEB_ROOT`, like this:

```
path = clean_path(request_uri.path)
```

After adding this to your web server, restart it and try to visit a path outside
the web root.

Visit `http://localhost:2345` in your browser and your file should be displayed.
You should also find that visiting relative paths should not allow you to escape
the document root. For example, `http://localhost:2345/../http.rb` should give a
404.

## Serving directories

Start the server, and then open your web browser to
http://localhost:2345/index.html. You should see the index.html file you put in
the public directory. Congratulations, you're serving files over HTTP!

---

If you visit `http://localhost:2345` in your web browser, you'll see a 404 Not
Found response, even though you've created an index.html file. Most real web
servers will serve an index file when the client requests a directory. Let's
implement that.

After cleaning the path, check to see if the file is a directory. If it is, join
"index.html" onto the path. If there's no file named "index.html", that's no
problem -- the next statement checks to see if the file exists, so if it
doesn't, the server will simply return an HTTP 404 Not Found response.

```ruby
path = clean_path(request['PATH_INFO'])
 
if File.directory?(path)
  path = File.join(path, 'index.html')
end

if File.exist?(path) && !File.directory?(path)
  # .. serve the file
else
  # .. return 404 Not Found
end
```
  
Notice how we still check to see if the file is a directory. That's because
there's nothing a directory from being named "index.html". It's better to be
safe than sorry.

Here's the final listing for the web server:

```ruby
require 'socket'
require 'uri'
 
# Files will be served from this directory
WEB_ROOT = './public'
 
DEFAULT_CONTENT_TYPE = 'application/octet-stream'
CONTENT_TYPE_MAPPING = {
  'html' => 'text/html',
  'txt' => 'text/plain',
  'png' => 'image/png',
  'jpg' => 'image/jpeg'
}
 
def content_type(path)
  ext = File.extname(path).split(".").last
  CONTENT_TYPE_MAPPING[ext] || DEFAULT_CONTENT_TYPE
end
 
def clean_path(path_info)
  clean = []
 
  # The path is URL-encoded, so it must be unescaped to translate it to a filesystem path
  path = URI.unescape(path_info)
 
  # Split the path into components
  parts = path.split("/")
  parts.each do |part|
    # skip any empty or current directory (".") path components
    next if part.empty? || part == '.'
    # If the path component goes up one directory level (".."), remove the last clean component
    # Otherwise, add the component to the Array of clean components
    part == '..' ? clean.pop : clean << part
  end
 
  # return the web root joined to the clean path 
  File.join(WEB_ROOT, *clean)
end
 
server = TCPServer.new('localhost', 2345)
 
loop do
  # Open a socket to communicate with the client
  socket = server.accept
  # Read the first line of the HTTP request
  request_line = socket.gets
 
  puts request_line
  
  # Request-Line looks like this: GET /path?foo=bar HTTP/1.1
  # Splitting on spaces will give us an Array like ["GET", "/path?foo=bar", "HTTP/1.1"]
  request_line_items = request_line.split(" ")
  # Create a URI object so we can easily get the path part of the Request-URI
  request_uri = URI(request_line_items[1])
 
  path = clean_path(request_uri.path)
 
  if File.directory?(path)
    path = File.join(path, 'index.html')
  end
 
  if File.exist?(path) && !File.directory?(path)
    file = File.new(path)
 
    socket.print "HTTP/1.1 200 OK\r\n"
    socket.print "Content-Type: #{content_type(file)}\r\n"
    socket.print "Content-Length: #{File.size(path)}\r\n"
    socket.print "\r\n"
    file.each do |line|
      socket.print line
    end
  else
    message = "File not found"
    socket.print "HTTP/1.1 404 Not Found\r\n"
    socket.print "Content-Type: text/plain\r\n"
    socket.print "Content-Length: #{message.size}\r\n"
    socket.print "\r\n"
    socket.print "#{message}\r\n"
  end
 
  socket.close
end
```

## Next steps

Congratulations! You've reviewed how HTTP works, then written a simple web
server that can serve up files from a directory. You've also examined one of the
most common security problems with web applications and fixed it.

However, the server we've written is extremely limited. Here are some ideas for
improving the server:

* According to the HTTP 1.1, specification a server must minimally 
respond to GET and HEAD to be compliant. Implement the HEAD response.
* Add error handling that returns a 500 response to the client 
if something goes wrong with the request.
* Make the web root directory and port configurable.
* Add support for POST requests. You could implement CGI by executing 
a script when it matches the path, or implement the Rack spec to 
let the server serve Rack apps with `call`.

