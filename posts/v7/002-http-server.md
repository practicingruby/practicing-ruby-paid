# Writing a simple HTTP server in Ruby

Implementing a simple but real project is helpful when you're learning a new programming language. In the same way, implementing a simpler version of a technology you use every day can help you understand it better.

With that in mind, let's right a simple HTTP server in Ruby. The completed program will be able to serve files from your computer to a web browser using only the libraries in core Ruby (not counting WEBrick, of course!).

## HTTP Basics

When you click a link to `http://example.com/file.txt` in your web browser, what happens? 

The browser issues an HTTP request by opening a TCP socket connection to `example.com` on port 80. The server accepts the connection and opens another socket for bi-directional communication.

Once the connection has been made, the HTTP client sends the request over the connection:

    GET /file.txt HTTP/1.1
    User-Agent: ExampleBrowser/1.0
    Host: example.com
    Accept: */*
    

Note, all lines need to end with `\r\n`, rather than just `\n`.
    
The server parses the request. The first line is the Request-Line which contains the HTTP method (`GET`), Request-URI (`/file.txt`), and HTTP version (`1.1`). Subsequent lines are headers, key-value pairs delimited by ":". After the headers is a blank line followed by an optional a message body (not present in this example). To determine how much data to read from the message body of the request, the server parses the Content-Length header or uses [Chunked-Encoding](http://en.wikipedia.org/wiki/Chunked_transfer_encoding).

Using the same connection, the server responds:

    HTTP/1.1 200 OK
    Content-Type: text/plain
    Content-Length: 11
    
    hello world

The server will close the socket after finishing the response to terminate the connection.

## Writing the simplest Ruby HTTP server

To begin, let's write the simplest thing that could possibly work: a web server that always responds "hello world" with HTTP 200 to any request.

Requiring the `socket` library allows us to use the `TCPServer` class. `TCPServer` waits for client connections and returns a `TCPSocket` for communication with the client from its `accept` method.

    require 'socket'
    
    server = TCPServer.new('localhost', 2345)    

    loop do
      socket = server.accept
      line = socket.gets
      puts line
      socket.print "Bye."
      socket.close
    end

The `TCPServer` is initialized with a hostname and port to bind to.

Once the `TCPServer` is initialized, we can loop forever, creating new sockets to handle connections with the `accept` method, which returns a `TCPSocket`. 

To read a line off of the `TCPSocket`, we can use `gets` (provided by `TCPSocket`'s parent class `IO`), and to send data to the client, we can use `TCPSocket#print`.
   
Putting it all together, here is a simple HTTP server:

    require 'socket'
     
    server = TCPServer.new('localhost', 2345)
     
    loop do
      socket = server.accept
      # Read the first line of the request (the Request-Line)
      request = socket.gets
    
      puts request
     
      response = "Hello world!\n"
     
      socket.print "HTTP/1.1 200 OK\r\n"
      socket.print "Content-Type: text/plain\r\n"
      socket.print "Content-Length: #{response.size}\r\n"
      socket.print "\r\n"
      socket.print response
      socket.close
    end

In this example, we're ignoring the Request-Line and returning the same response for every request, so we'll simply output the first line and ignore the rest of the request. In creating the response, we've set the Content-Type and Content-Length headers. These headers are important for letting the client know what kind of data we are returning and how big it is. As we saw above, all HTTP header lines must end in CRLF (`\r\n`). There's also an empty line between the headers and the response body. 

Start your server and try opening http://localhost:2345/anything in a browser. You should see the "Hello world!" message. Meanwhile, in the output for the HTTP server, you should see the request being logged:

    GET /anything HTTP/1.1
   
Next, open another shell and test it with `curl`:

    curl --verbose -XGET http://localhost:2345/anything
    
You'll see the detailed request and response headers:

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

Congratulations, you've written a simple HTTP server!

## Serving files over HTTP

Let's expand our example to be able to serve files from a directory instead of just outputting "Hello world!"

This will require adding some additional functionality to the server:

* Translate the Request-URI into a local path.
* Return 404 Not Found if the path isn't available.
* Determine the Content-Type of the file based on its extension.
* Output the contents of the file to the socket.

First, create a subdirectory called "public" to hold the files to serve. This will be the server's web root directory. Put an index.html file in that directory.

Now that we care what the request was, we'll need to parse the Request-URI from the Request-Line in the HTTP request and convert it into a filesystem path by joining it to the web root directory.

Once we've translated the Request-URI into a filesystem path, we check to see if it exists and isn't a directory. If so, we write an HTTP response with the Content-Type and Content-Length headers. The body of the response is created by enumerating the lines of the file using `each` and printing each one to the socket.

If the file doesn't exist, we'll respond with HTTP 404 Not Found, along with a message for the browser to display.

Here is the enhanced code. Note that we've added a helper method `content_type` to return the content type of a file based on its extension.

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
      # The path is URL-encoded, so it must be unescaped to translate it to a filesystem path
      path_info = URI.unescape(request_uri.path)
     
      path = File.join(WEB_ROOT, path_info)
     
      # FIXME: Horrible security problem!
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

Start the server, and then open your web browser to http://localhost:2345/index.html. You should see the index.html file you put in the public directory. Congratulations, you're serving files over HTTP!

However, this implementation has a very bad security problem that has affected many, many web servers and CGI scripts over the years: the server will happily serve up any file, even if it's outside the `WEB_ROOT`.

Consider a request like this:

    GET /../../../../etc/passwd HTTP/1.1
    
On my system, when `File.join` is called on this path, the ".." path components
will cause it escape the `WEB_ROOT` directory and serve the `/etc/passwd` file.
Yikes! The `PATH_INFO` must be sanitized before use to prevent problems like this. (Note: You may need to use `curl` to demonstrate this because browsers may change the path to remove the ".." before sending it to the server.)

Since security code is notoriously difficult to get right, we will borrow some from [`Rack::File`](https://github.com/rack/rack/blob/master/lib/rack/file.rb) (In fact, this code was added to `Rack::File` [in response to a security vulnerability](http://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2013-0262).), a Rack application that serves files.

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

The `clean_path` method must be called before joining the path with the
`WEB_ROOT`, like this:

    path = clean_path(request_uri.path)

After adding this to your web server, restart it and try to visit a path outside the web root.

Visit `http://localhost:2345` in your browser and your file should be displayed. You should also find that visiting relative paths should not allow you to escape the document root. For example, `http://localhost:2345/../http.rb` should give a 404.

## Serving directories

If you visit `http://localhost:2345` in your web browser, you'll see a 404 Not Found response, even though you've created an index.html file. Most real web servers will serve an index file when the client requests a directory. Let's implement that.

After cleaning the path, check to see if the file is a directory. If it is, join "index.html" onto the path. If there's no file named "index.html", that's no problem -- the next statement checks to see if the file exists, so if it doesn't, the server will simply return an HTTP 404 Not Found response.

    path = clean_path(request['PATH_INFO'])
     
    if File.directory?(path)
      path = File.join(path, 'index.html')
    end

    if File.exist?(path) && !File.directory?(path)
      # .. serve the file
    else
      # .. return 404 Not Found
    end
  
Notice how we still check to see if the file is a directory. That's because there's nothing a directory from being named "index.html". It's better to be safe than sorry.

Here's the final listing for the web server:

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

## Next steps

Congratulations! You've reviewed how HTTP works, then written a simple web server that can serve up files from a directory. You've also examined one of the most common security problems with web applications and fixed it.

However, the server we've written is extremely limited. Here are some ideas for improving the server:

* According to the HTTP 1.1, specification a server must minimally respond to GET and HEAD to be compliant. Implement the HEAD response.
* Add error handling that returns a 500 response to the client if something goes wrong with the request.
* Make the web root directory and port configurable.
* Add support for POST requests. You could implement CGI by executing a script when it matches the path, or implement the Rack spec to let the server serve Rack apps with `call`.

