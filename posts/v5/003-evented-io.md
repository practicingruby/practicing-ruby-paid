*BIO GOES HERE*

Network I/O in Ruby is so simple: 

```ruby
require 'socket'

# Start a server on port 9234
server = TCPServer.new('0.0.0.0', 9234)

# Wait for incoming connections
while io = server.accept
  io << "HTTP/1.1 200 OK\r\n\r\nHello world!"
  io.close
end

# Visit http://localhost:9234/ in your browser.
```

Boom, a server is up and running! There are certain disadvantages though: We
can only handle one connection at a time. We can also only have one *server*
running at a time. There's no understatement in saying that this can be quite
limiting. 

There are several ways to improve this situation, but lately we've seen an
influx of event-driven solutions. [Node.js][nodejs] is just an event-driven I/O-library
built on top of JavaScript. [EventMachine][em] has been a solid solution in the Ruby
world for several years. Python has [Twisted][twisted], and Perl has so many they even
have [an abstaction around them][anyevent].

While they might seem like silver bullets, there are subtle details that
you'll have to think about. You can accomplish a lot by following simple rules
("don't block the thread"), but I always prefer to know precisely what I'm
dealing with. Besides, if doing regular I/O is so simple, why does
event-driven I/O has to be looked at as black magic?

That's why we're going to implement an event loop in this article. Yep, that's
right; we'll capture the core part of EventMachine/Node.js/Twisted in about
150 lines of Ruby. It won't be performant, it won't be test-driven, it won't
be solid, but it will use the exact same concepts as in all of these great
projects. This is in fact how they work.

Let's start.

## Events

First of all we need, obviously, events! With no further ado:

```ruby
module EventEmitter
  def _callbacks
    @_callbacks ||= Hash.new { |h, k| h[k] = [] }
  end

  def on(type, &blk)
    _callbacks[type] << blk
    self
  end

  def emit(type, *args)
    _callbacks[type].each do |blk|
      blk.call(*args)
    end
  end
end

class HTTPServer
  include EventEmitter
end

server = HTTPServer.new
server.on(:request) do |req, res|
  res.respond(200, 'Content-Type' => 'text/html')
  res << "Hello world!"
  res.close
end

# When a new request comes in, the server will run:
#   server.emit(:request, req, res)

```

EventEmitter is a module which we can include into classes that can send and
receive events. In some sense this is the most important part of our event
loop: It defines how we use and reason about events in the system. Changing it
later will introduce changes all over the place.

Some notes:

1. Blocks don't have to be invoked right away, but can be stored and invoked
   later.

2. Have you seen "Hash.new with block" before? It's definitely one of the most
   useful "easter eggs" in Ruby.

3. Why is it useful return `self` in #on?

4. You might find it useful to implement a special "all" event which is
   triggered for every event that is emitted.

## The Loop

Next up we need something to fire up these events:

```ruby
class IOLoop
  # List of streams that this IO loop will handle.
  attr_reader :streams

  def initialize
    @streams = []
  end
  
  # Low-level API for adding a Stream.
  def <<(stream)
    @streams << stream
    stream.on(:close) do
      @streams.delete(stream)
    end
  end

  # Some useful helpers:
  def io(io)
    stream = Stream.new(io)
    self << stream
    stream
  end

  def open(file, *args)
    io File.open(file, *args)
  end

  def connect(host, port)
    io TCPSocket.new(host, port)
  end

  def listen(host, port)
    server = Server.new(TCPServer.new(host, port))
    self << server
    server.on(:accept) do |stream|
      self << stream
    end
    server
  end

  # Start the loop by calling #tick over and over again.
  def start
    @running = true
    tick while @running
  end

  # Stop/pause the event loop after the current tick.
  def stop
    @running = false
  end

  def tick
    @streams.each do |stream|
      stream.handle_read  if stream.readable?
      stream.handle_write if stream.writable?
    end
  end
end

# Usage:

l = IOLoop.new

ruby = i.connect('ruby-lang.org', 80)  # 1
ruby << "GET / HTTP/1.0\r\n\r\n"       # 2

# Print output
ruby.on(:data) do |chunk|
  puts chunk   # 3
end

# Stop IO loop when we're done
ruby.on(:close) do
  l.stop       # 4
end

l.start        # 5
```

This shows the general flow of an event loop:

1. Find new events.
2. Run callbacks based on the event.
3. Try again.

Notice here that IOLoop#start blocks everything (until IOLoop#stop is called).
Everything after IOLoop#start will happen in callbacks which means that the
control flow can be surprising. You might think that you're writing data in
step 2, but that's just stored locally in a buffer. It's not until the event
loop has started (in step 5) that it's actually sending the data.

In our I/O loop we'll implement Stream#handle\_read and #handle\_write and they
will be responsible for reading/writing and emitting other events.

This should also make it clear why it's so terrible to block inside a
callback. Have a look at this call graph:

```
# indentation means that a method/block is called
# deindentation means that the method/block returned

tick (10 streams are readable)
  stream1.handle_read
    stream1.emit(:data)
      your callback

  stream2.handle_read
    stream2.emit(:data)
      your callback
        you have a "sleep 5" inside here

  stream3.handle_read
    stream3.emit(:data)
      your callback
  ...
```

By blocking inside a callback, the I/O loop has to wait 5 seconds before it's
able to continue calling the rest of the callbacks.

### IO events

At the most basic level, there are only two events for an IO object:

1. Readable: The IO is readable; data is waiting for us. Examples:
   Data has been read from the disk or a client/server has sent you data.

2. Writable: The IO is writable; we can write data.

These might sound a little confusing: How can a client know that the server
will send us data? It can't. Readable doesn't mean "the server will send us
data", it means "the server has already sent us data". In that case the data
is handled by the kernel in your OS. When you "read" from an IO object you're
actually just copying bytes from the kernel.

If you don't read from an IO, the kernel's buffer will become full and the
sender's IO will no longer be writable. The sender will then have to wait
until the receiver can catch up and free up the kernel's buffer.

The goal of an I/O loop is to produce some more usable events:

1. Data: A chunk of data was sent to us.
2. Close: The IO was closed.
3. Drain: We've sent all buffered outgoing data.
4. Accept: A new connection was opened (only for servers).

## Dealing with IOs

There are various ways to read from a IO object in Ruby:

```ruby
data = io.read
data = io.read(12)
data = io.readpartial(12)
data = io.read_nonblock(12)
```

`io.read` reads until the IO is closed (e.g. end of file, server closes the
connection etc.) 

`io.read(12)` reads until it has received exactly 12 bytes.

`io.readpartial(12)` waits until the IO becomes readable, then it reads *at
most* 12 bytes. So if a server only sent 6 bytes, readpartial will return
those 6 bytes. If you had used `read(12)` it would wait until 6 more bytes are
sent.

`io.read_nonblock(12)` will read at most 12 bytes if the IO is readable. It
raises IO::WaitReadable if the IO is not readable.

For writing there's two methods:

```ruby
length = io.write(str)
length = io.write_nonblock(str)
```

`io.write` writes the whole string to the IO; waiting until the IO becomes
writable if necessary. Returns the number of bytes written (which should
always be equal to the number of bytes in the original string).

`io.write_nonblock` writes as many bytes as possible until the IO becomes
non-writable, returning the number of bytes written. Raises IO::WaitWritable
if the IO is not writable.

## Getting real with IO.select

I'm not going to implement Stream#readable? or #writable?. It's a terrible
solution to loop over every stream object in Ruby and check if it's
readable/writable over and over again. This is really just not a job for Ruby;
it's too far away from the kernel.

Luckily, the kernel exposes ways to efficiently detect readable and writable
IOs. The simplest (and cross-platform) is called select(2) and is available in
Ruby as IO.select:

```
IO.select(read_array [, write_array [, error_array [, timeout]]])

Calls select(2) system call. It monitors supplied arrays of IO objects, waits
until one or more IO objects are ready for reading, writing, or have errors.
It returns an array of those IO objects which need attention. It returns nil
if the optional timeout (in seconds) was supplied and has elapsed.
```

With this knowledge we can write a way better #tick:

```ruby
class IOLoop
  def tick
    r, w = IO.select(@streams, @streams)
    r.each do |stream|
      stream.handle_read
    end
  
    w.each do |stream|
      stream.handle_write
    end
  end
end
```

`IO.select` will block until some of our streams become readable or writable
and then return those streams.

## Handling read and write

All right, I've used Stream all over the code, now it's time to implement it.

```ruby
class Stream
  # We want to bind/emit events
  include EventEmitter

  def initialize(io)
    @io = io
    # Store outgoing data in this String.
    @writebuffer = ""
  end

  # This tells IO.select what IO to use
  def to_io; @io end

  def <<(chunk)
    # Append to buffer; #handle_write is doing the actual writing.
    @writebuffer << chunk
  end
  
  def handle_read
    chunk = @io.read_nonblock(4096)
    emit(:data, chunk)
  rescue IO::WaitReadable
    # Oops, turned out the IO wasn't actually readable.
  rescue EOFError, Errno::ECONNRESET
    # IO was closed
    emit(:close)
  end
  
  def handle_write
    return if @writerbuffer.empty?
    length = @io.write_nonblock(@writebuffer)
    # Remove the data that was successfully written.
    @writebuffer.slice!(0, length)
    # Emit "drain" event if there's nothing more to write.
    emit(:drain) if @writebuffer.empty?
  rescue IO::WaitWritable
  rescue EOFError, Errno::ECONNRESET
    emit(:close)
  end
end
```

If you've been following along from the beginning, I believe most of this code
should be self-explanatory.

We also need a class for handling the server:

```ruby
class Server
  include EventEmitter

  def initialize(io)
    @io = io
  end

  def to_io; @io end
  
  def handle_read
    sock = @io.accept_nonblock
    emit(:accept, Stream.new(sock))
  rescue IO::WaitReadable
  end

  def handle_write
    # do nothing
  end
end
```

A server is a very simplified stream: Instead of reading data, we can *accept*
connections. As usual, we're doing this in a non-blocking way.

### Smarter writing

The IO will (hopefully, and most likely) be writable most of the time.  This
means that even though we have nothing to write (i.e. the write buffer is
empty), we're still passing it to IO.select. An easy optimization is to only
check for writability on the streams that have pending outgoing data: 

```ruby
r, w = IO.select(@streams, @streams.select { |s| !s.writebuffer.empty? })
```

If you don't want to run an Array#select on every tick you can also solve this
by having two separate arrays (`IO.select(@readers, @writers)`) and using the
`drain`-callback to remove streams from writers when the buffer is empty.

## Timers

You will find yourself severely limited without timers in IOLoop. Something as
simple as "keep this connection open for 5 seconds" becomes impossible without
explicit support for timers by the event loop. (Well, technically, you *can*
block the whole event loop for 5 seconds, but this is probably not what you
want.)

Luckily for us, IO.select accepts a *timeout* as the fourth parameter:

```ruby
class IOLoop
  def initialize
    # ...
    @timers = []
  end

  def timer(sec, &blk)
    @timers << [Time.now + sec, blk]
    @timers.sort!
  end
  
  def tick
    now = Time.now
    # Remove timers that have passed.
    passed = @timers.delete_if { |time, _| time <= now }

    if timer = @timers.first
      # If there are any pending timers, we want only want to block     
      # until the number of seconds
      timeout = timer[0] - now
    end

    # Invoke the timers
    passed.each { |_, blk| blk.call }

    r, w = IO.select(@streams, @streams, nil, timeout)
    # …
  end
end
```

Be aware that these timers do not have very high precision.

## Notes on select(2)

select(2) (the syscall that IO.select is based on) has *linear performance*.
This means that handling 10 000 streams is 10 000 times as slow as handling 1
stream, which makes select(2) a poor solution when you expect many
connections. There are alternative solutions, namely epoll(2) in Linux and
kqueue(2) in BSD, but these are not cross-platform nor exposed by Ruby by
default. There's also cross-platform abstractions on top of
select/epoll/kqueue: Both [libev][libev] and [libuv][libuv] (used by Node.js)
uses either select, epoll or kqueue depending on the platform.

If you want to experiment with these high-performance libraries in Ruby, I'd
recommend the [Nio4r-project][nio4r] which wraps libev in a clean and simple
matter.  You should have no problem replacing IO.select in our little IOLoop
with NIO::Selector.

## Back pressure

An observant reader might notice a slight problem with our `@writebuffer`:
it's unbounded. If the receiver is not attempting to read the incoming data at
all, the socket will become non-writable. This is called [back pressure][bp],
instead of flooding the network, the receiver communicates that it can't
handle more incoming data and the sender pauses.

The problem with our event loop (and many others) is that there is no
connection between what is *producing* the data and what is *sending* it.
Anyone can produce data by calling `Stream#<<`, but there's no way for the
event loop to tell these producers that they should pause for some seconds.

Our event loop will happily buffer the data forever and it will silently
become a memory "leak". It's not a true leak since the memory will be freed
when the receiver starts accepting data or the connection is closed, but
*practically* it will behave as a leak.

If you're using event-driven I/O and continuously sending data you should
examine how your event loop handles back pressure:

```ruby
require 'socket'

# Open connection
socket = TCPSocket.new(IP, PORT)

# Send initial handshake so the server will start streaming
socket << "Do something"

# And wait...
sleep
```

If the memory usage slowly increases over time, you're vulnerable to a very
simple DoS attack. If the connection is suddenly cut off, you might also cut off
"real" clients. If nothing special happens: You're handling back pressure
correctly.

Handling back pressure using blocking I/O is much simpler. The call to #write
will always block until the socket is writable so there's no way to produce
more data until the receiver has acknowledged the previous chunk.

## Conclusion

Lalalala?

[nodejs]: http://nodejs.org/
[em]: http://rubyeventmachine.com/
[twisted]: http://twistedmatrix.com/
[anyevent]: http://metacpan.org/module/AnyEvent
[libev]: http://software.schmorp.de/pkg/libev.html
[libuv]: https://github.com/joyent/libuv
[nio4r]: https://github.com/tarcieri/nio4r
[bp]: http://en.wikipedia.org/wiki/Back_pressure#Back_pressure_in_information_technology


