Start with a story about what happens when I type a message into an
IRC channel, and how it gets to you. (Sockets, IRC protocol,
client->server->client etc).

LOOKING AT DIFFERENT WAYS TO STORE, PROCESS, REPRESENT, AND INTERPRET
A SINGLE SIMPLE MESSAGE.


* Exposing meaning without knowing how to process something
* What it means to understand a message (we'll focus on the first tier)
* Direct representation vs indirect representation via generalized constructs
* The inherent limitation of syntax, no matter how simple.
* Processing without knowing meaning (messagepack)
* Unification (formal grammars)
* Commentary on the gradient of information formats from binary to English. (no
free lunch, at each level you gain something and you lose something, so it's
important to consider context if you need to design a format or protocol).
There is also a weird cross-over effect in which they end up being so
similar and so different at the same time.


> CREDIT: GEB.

TODO: Come up with a suitable definition of "information",
basically it's an interpeted message that we can discern the
structure and meaning of.
http://en.wikipedia.org/wiki/Information

THOUGHT: As structure becomes more explicit, meaning becomes less specific.
(or something like that)

THOUGHT: The concept of an array (or any entitity) isn't tied up its
representation, but instead exists in our heads (meaning), and in 
the symbolic transformations carried out by the computer (structure).

THOUGHT: The more expressive the "language", the more edge cases
and rules you'll need to address, but the tradeoff is that you
can precisely describe more complex structures.

To begin our explorations, let's look at an example from the Internet
Relay Chat (IRC) protocol. The following string represents the
command that you'd send to an IRC server to post a message
to a particular channel:

```ruby
"PRIVMSG #practicing-ruby-testing :Seasons greetings to you all!\r\n"
```

Even if you've never used IRC before or looked into its implementation
details, you can extract a great deal of meaning from this single line 
of text. The structure is very simple, so it's fairly obvious that
`PRIVMSG` represents a command, `#practicing-ruby-testing` represents
the channel, and that the message to be delivered is 
`"Seasons greetings to you all!"`. If I asked you to parse this
string to produce the following array, you probably would have
no trouble doing so without any further instruction:

```ruby
["PRIVMSG", "#practicing-ruby-testing", "Seasons greetings to you all!"]
```

But if this were a real project and not just an academic exercise,
you might start to wonder more about the nuances of the protocol. Here
are a few questions that might come up after a few minutes of
careful thought:

* What is the significance of the `:` character? Does it always signify 
the start of the message contents, or does it mean something else?

* Why does the message end in `\r\n`? Can messages contain newlines,
and if so, should they be represented as `\n` or `\r\n`, or something
else entirely?

* Will messages always take the form `"PRIVMSG #channelname :Message Body\r\n"`, 
or are their cases where additional parameters will be used?

* Can channel names include spaces? How about `:` characters?

Try as we might, no amount of analyzing this single example will answer 
these questions for us. That leads us to a very important point: 
Understanding  the *meaning* of a message doesn't necessarily mean that 
we know how to process the information contained within it.

## Processing Something Something

Because we can't reliably infer how to process information by simply looking at
examples, we rely on formal specifications to guide us in our interpretation
of the structure and meaning of encoded messages.

For a piece of information to be useful in a software system, it needs to be
*well-formed*, *valid*, and *correct*. Although these three properties may
appear to be synonymous to one another at first glance, they actually
represent a strict hierarchy that spans the gap between the meaningless
and meaningful. Here's why:

* If a message is not *well-formed*, it means that it does not even follow the
basic structural rules of the underlying protocol or format. A strict
processor will reject these messages out of hand, while a more flexible
system might apply some error-correction routines to transform the
ill-formed message into a well-formed one. In this case, your message
*might* get interpreted as you'd expect it would, but there's no guarantee.
DETERMINING WHETHER A MESSAGE IS WELL-FORMED CAN BE DONE BY DIRECT INSPECTION
AS LONG AS YOU KNOW THE PROCESSING/PARSING RULES.
(writing a channel name in the wrong format)

* If a message is *well-formed* but *invalid*, it's entirely up to the
software that processes it to decide how to respond. Unless the behavior
for handling invalid messages is formally specified, it's anybody's
guess what a software system might do with an invalid message. You
might get an error message of some sort, or you might get no response
at all. In less optimistic scenarios, you might get a false-positive
response that indicates that your message was processed correctly,
only to find out that it wasn't interpreted as you expected it would be.
In the most hellish of circumstances, you make end up triggering
some undefined behavior that can fall anywhere on the spectrum from
weird little glitches to system crashes to nukes being launched at 
the moon (FOOTNOTE: fork fail) .
DETERMINING WHETHER A MESSAGE IS VALID DEPENDS ON LOGIC /
APPLICATION STATE. I.E. THE SYSTEM NEEDS TO TELL YOU,
YOU CAN'T JUST GUESS FROM THE PROCESSING RULES (posting to
a channel that doesn't exist)

* If a message is both *well-formed* and *valid*, it still isn't
guaranteed to produce a *correct* result. This is a more subtle issue, 
and typically involves either system behavior that's underspecified, 
or a lack of understanding of the specified behavior by implementers.
Sometimes messages can be processed incorrectly because of bugs
in the systems that interpret them, but just as often it is
the case that the programmer who encoded the message thought it
meant one thing when it really meant something else.
DETERMINING CORRECTNESS CAN ONLY BE DONE BY VERIFYING BEHAVIOR
AFTER AN ACTION IS CARRIED OUT.

Perhaps unsurprisingly, many problematic behaviors and bugs in
software systems come from these three basic requirements for 
meaningful information processing. Without satisfying all
three of them, the best we can hope for are systems that 
"kind-of, sort-of work, some of the time."

## Structure and simplicity SOMETHING SOMETHING

Earlier we looked at an example of how chat messages are represented 
in the IRC protocol. On the surface level, the simple text-based
format made it easy for us to identify the structure and meaning
of different parts of the command format. But when we thought
a little more about what it would take to actually implement
the protocol, we quickly ran into several questions about
how to construct well-formed messages.

A lot of the questions we came up with had to do with basic syntax
rules, which is only natural when exploring an unfamiliar information
format. For example, we can guess that the `:` symbol is a special character 
in the following string, but we can't reliably guess its meaning without 
reading the IRC command specification:

```ruby
"PRIVMSG #practicing-ruby-testing :Seasons greetings to you all!\r\n"
```

To see the effect of syntax on our interpretation of information
formats, consider what happens when we shift the representation 
of a chat message into a generic structure that
we are already familiar with, such as a Ruby array: 

```ruby
["PRIVMSG", "#practicing-ruby-testing", "Seasons greetings to you all!"]
```

Looking at this information, we still have no idea whether it 
constitutes a well-formed message to be processed by 
our hypothetical IRC-like chat system. But because we know Ruby's 
syntax, we understand what is being communicated here at
a primitive level.

Before when we looked at the `PRIVMSG` command expressed in
the format specified by the IRC protocol, we weren't able to
reliably determine the rules for breaking the message up
into its parts by looking at a single example. Because
we didn't already have its syntax memorized, we wouldn't even
be able to reliably parse IRC commands, let alone process them.
But as Ruby programmers, we know what array and string literals
look like, and so we know how to map their syntax to the concepts
behind them.

The mundane observation to be made here is that it's easier 
to understand a format you're familiar with than it is to 
interpret one you've never seen before. A far more interesting
point to discover is that these two examples have fundamental
differences in meaning, even if they can be interpreted in
a way that makes them equivalent to one another.

Despite their superficial similarities, the two examples
we've looked at operate at completely different
levels of abstraction. The IRC-based example directly 
encodes the concept of a "chat command", whereas 
our Ruby example encodes the concept of an "array of strings". 
In that sense, the former is a direct representation of a 
domain-specific concept, and the latter is a indirect 
representation built up from general-purpose data structures.
Both can express the concept a chat command, but they're not
cut from the same cloth.

Let's use a practical examples to explore why this difference
in structure matters. Consider what might happen if we attempted
to allow whitespace in chat channel names, i.e. 
`#practicing ruby testing` instead of `#practicing-ruby-testing`.
By directly substituting this new channel name into our `PRIVMSG`
command example, we get the string shown below:

```ruby
"PRIVMSG #practicing ruby testing :Seasons greetings to you all!\r\n"
```

Here we run into a syntactic challenge: If we allow for channel
names to include whitespace, we need to come up with more complex
rules for splitting up the command into its different parts. But
if we decide this is an ill-formed string, then we need to come
up with a syntactic rule that says that the channel parameter
cannot include spaces in it. Either way, we need to come up
with a formal constraint that will be applied at parse time,
before processing even begins.

Now consider what happens when we use Ruby syntax instead:

```ruby
["PRIVMSG", "#practicing ruby testing", "Seasons greetings to you all!"]
```

This is without question a well-formed Ruby array, and it will
be successfully parsed and turned into an internal data structure.
By definition, Ruby string literals allow whitespace in them, 
and there's no getting around that without writing our own 
custom parser. So while the IRC example *must* consider the meaning
of whitespace in channel names during the parsing phase, our
Ruby example *cannot*. Any additional constraints placed on the 
format of channel names would need to be done via logical 
validations rather than syntactic rules.

The key realization here is that the concepts we're expressing
when we encode something in one syntax or another have meaning
beyond the raw data that they represent. In the IRC protocol
a 'channel' is a defined concept at the symbolic level, with a 
specific meaning to it. When we represent it using a Ruby
string, we can only approximate the concept by starting with
a more general structure and then applying logical rules to
it to make it a more faithful representation of a concept
it cannot directly express. This is not unlike translating
a word from one spoken language to another which doesn't
have a precisely equivalent concept.

A STRING HAS THE PROPERTY/CONSTRAINTS OF "A SEQUENCE OF BYTES/CHARACTERS"
AN IRC CHANNEL NAME IS A RESTRICTED SUBSET OF THAT CONCEPT
EXPRESSING THE CONCEPT DIRECTLY REMOVES THE NEED TO DERIVE IT

## Ambiguity

Consider once more our fascinating Ruby example:

```ruby
["PRIVMSG", "#practicing-ruby-testing", "Seasons greetings to you all!"]
```

We've seen that because its structure is highly generic, its
representation is very permissive. Nearly any sequence of
printable characters can be expressed within a Ruby string literal,
and so there isn't much ambiguity in expression of ordinary strings.

However, like all text-based formats, there are things that without
special consideration, could lead to ambiguous or incomprehensible
messages. For example, consider strings which have `"` characters
within them:

```
"My name is: "Gregory"\n"
```

The above will generate syntax error in Ruby, becasuse it ends up
getting parsed as the string `"My name is: "`, followed immediately
by the constant `Gregory`, followed by the string `"\n"`. Ruby
understandably has no way of interpreting that nonsense, so
the parse fails. 

If we were only concerned with parsing string literals, we could 
find a way to resolve these ambiguities by adding some special 
parsing rules, but Ruby has a much more complex grammar across
its entire featureset. For that reason, it expects you to be
a bit more explicit when dealing with edge cases like this one.
To get our string to parse, we'd need to do something like this:

```
"My name is: \"Gregory\"\n"
```

By writing <tt>\"</tt> instead of <tt>"</tt>, we tell the parser
to treat the quote character as just another character in the string
rather than a symbolic *end-of-string* marker. The <tt>\</tt> acts
as an escape character, which is useful for resolving these sorts
of ambiguities. The cost of course is that <tt>\</tt> itself
becomes a potential source of ambiguity, so you end up having to write
<tt>\\</tt> instead of <tt>\</tt> to express backslashes in Ruby
string literals.

Edge cases of this sort arise in any reasonably expressive text-based format.
They are often easy to resolve by adding a few more rules, but in many
cases the addition of new processing rules add an even more subtle layer
of corner cases to consider (as we've seen w. the <tt>\</tt> character).
Resolving minor ambiguities comes natural to humans because we can
guess at the meaning of a message, but cold-hearted computers
can only follow the explicit rules we've given them.

## Speaking the language of the beast

One possible solution to the syntactic ambiguity problem is to represent information in
a way that is convenient for computers, rather than optimizing for
human readability. For example, here's the same array of strings
represented as a raw sequence of bytes in Messagepack format:

```
93 a7 50 52 49 56 4d 53 47 b8 23 70 72 61 63 74 69 63 69 6e 67 2d 72 75 62 
79 2d 74 65 73 74 69 6e 67 bd 53 65 61 73 6f 6e 73 20 67 72 65 65 74 69 6e 
67 73 20 74 6f 20 79 6f 75 20 61 6c 6c 21
```

At first, this looks like a huge step backwards, because it smashes our
ability to intuitively extract meaning from the message by simply
reading its contents. But when we discover that the vast majority of
these bytes are just encoded character data, things get a little
more comprehensible:

```ruby
"\x93\xA7PRIVMSG\xB8#practicing-ruby-testing\xBDSeasons greetings to you all!"
```

Knowing that most of the message is the same text we've seen in the other
examples, we only need to figure out what the few extra bytes of information
represent:

![](http://i.imgur.com/YAh5olr.png)

Like all binary formats, MessagePack is optimized for ease of processing
rather than human readability. Instead using text-based symbols to describe 
the structure of data, MessagePack uses an entirely numeric encoding format.

By switching away from brackets, commas, and quotation marks to arbitrary
values like `93`, `A7`, `B8`, and `BD`, we immediately lose the ability to
visually distinguish between the different structural elements of the 
message. This makes it harder to simply look at a message and know whether
or not it is well-formed, and also makes it harder to notice the connections
between the symbols and their meaning while reading an encoded message.

Let's take a moment to consider a practical example. If you squint really 
hard at the yellow boxes in the above diagram, you might
guess that `93` describes the entire array, and that `A7`, `B8`, and `BD`
all describe the strings that follow them. But `A7`, `B8`, and `BD` need to
be expressing more than just the concept of "a string", otherwise there
would be no need to use three different values. You might be able to
discover the underlying rule by studying the example for a while, but
it doesn't just jump out at you the way a pair of opening and closing
brackets might.

To avoid leaving you in suspense, here's the key idea: MessagePack
attempts to represent seralized data structures using as few bytes 
as possible, while making processing as fast as possible. To do this,
MessagePack uses type headers that tell you exactly what type of
data is encoded, and exactly how much space it takes up in 
the message. For small chunks of data, it conveys both of these
pieces of information using a single byte!

Take for example the first byte in the message, which has the
hexidecimal value of `93`. MessagePack maps the values `90-9F`
to the concept of *arrays with up to 15 elements*. This
means that an array with zero elements would have the type code 
of `90` and an array with 15 elements would have the type code
of `9F`. Following the same logic, we can see that `93` represents 
an array with 3 elements.

For small strings, a similar encoding process is used. Values in 
the range of `A0-BF` correspond to *strings with up to 31 bytes of data*.
All three of our strings are in this range, so to compute
their size, we just need to subtract the bottom of the range
from each of them:

```ruby
# note that results are in decimal, not hexidecimal
# String sizes are also computed explicitly for comparison

>> 0xA7-0xA0
=> 7
>> "PRIVMSG".size
=> 7

>> 0xB8-0xA0
=> 24
>> "#practicing-ruby-testing".size
=> 24

>> 0xBD-0xA0
=> 29
>> "Seasons greetings to you all!".size
=> 29
```

Piecing this all together, we can now see the orderly structure
that was previously obfuscated by the compact nature of the
MessagePack format:

![](http://i.imgur.com/H9lOSex.png)

Although this appears to be superficially similar to the structure
of our Ruby array example, there are significant differences that
become apparent when attempting to process the MessagePack data:

* In a text-based format you need to look ahead to find closing
brackets to match opening brackets, to organize quotation marks
into pairs, etc. In MessagePack format, explicit sizes for each
object are given so you know exactly where its data is stored
in the bytestream.

* Because we don't need to analyze the contents of the message
to determine how to break it up into chunks, we don't need
to worry about ambiguous interpretations of symbols in the data.
This avoids the need for introducing escape sequences for the
sole purpose of making parsing easier.

* The explicit separation of metadata from the contents of the
message makes it possible to read part of the message without
analyzing the entire bytestream. We just need to extract all
the relevant type and size information, and then from there
it is easy to compute offsets and read just the data we need.

The underlying theme here is that by compressing all of the
structural meaning of the message into simple numerical values,
we convert the whole problem of extracting the message into
a series of trivial computations: read a few bytes to determine
the type information and size of the encoded data, then
read some content and decode it based on the specified type,
then rinse and repeat.


## Abtract types

Even though representing our message in a binary format allowed
us to make information extraction simpler and more precise, 
the data type we used still corresponds to concepts that don't precisely
fit the intended meaning of our message.

One possible way to solve this conceptual problem is to completely 
decouple structure from meaning in our message format. To do that,
we could utilize MessagePack's abstract type mechanism --
resulting in a message similar to what you see below:

![](http://i.imgur.com/s3Rjgzz.png)

The `C7` type code indicates an abstract type, and is followed
by two additional bytes: the first provides an arbitrary type
id (between 0-127), and the second specifies how many bytes
of data to read in that format. After applying these rules,
we end up with the following structure:

![](http://i.imgur.com/AubaxCk.png)

The contents of each object in the array is the same as it always
has been, but now the types have changed. Instead of an
array composed of three strings, we now have an array that
consists of elements that each have their own type.

Although I've shown the contents of each object as text-based
strings in the above diagram for the sake of readability,
the MessagePack format does not assume that the data associated
with extended types will be text-based. The decision of
how to process this data (if at all) is left up to the decoder.

FIXME: LINK A REFERENCE IMPLEMENTATION

Without getting into too many details, let's consider how abstract
data types might be handled in a real Ruby program that processed
MessagePack-based messages. You'd need to make an explicit mapping
between type identifiers and the handlers for each type, perhaps
using an API similar to what you see below:

```ruby
data_types = { 1 => CommandName, 2 => Parameter, 3 => MessageBody }

command = MessagePackDecoder.unpack(raw_bytes, data_types)
#  [ CommandName <"PRIVMSG">, 
#    Parameter   <"#practicing-ruby-testing">, 
#    MessageBody <"Season greetings to you all!"> ]
```

Each handler would be responsible for transforming raw byte arrays
into meaningful data objects. For example, the following class might
be used to convert command parameters (e.g. the channel name) into
a text-based representation:

```ruby
class Parameter
  def initialize(byte_array)
    @text = byte_array.pack("C*")

    raise ArgumentError if @text.include?(" ")
  end

  attr_reader :text
end
```

The key thing to note about the above code sample is that
the `Parameter` does not simply convert the raw binary into
a string, it also applies a validation to ensure that the
string contains no space characters. This is a bit of a
contrived example, but it's meant to illustrate the ability
of custom type handlers to apply their own data integrity
constraints.

Earlier we had drawn a line in the sand between the 
array-of-strings representation and the IRC command format
because the former was forced to allow spaces in strings
until after the parsing phase, and the latter was forced
to make a decision about whether to allow them or not
before parsing could be completed at all. The use
of abstract types removes this seemingly arbitrary
limitation, allowing us to choose when and where to
apply our validations, if we apply them at all.

Another dividing wall that abstract types seem to blur for
us is the question of what the raw contents of our message
actually represent. Using our own application-specific type
definitions make it so that we never need to consider the
contents of our messages to be "strings", except as an
internal implementation detail. However, we rely
absolutely on our decoder to convert data that has been
tagged with these seemingly arbitrary type identifiers
into something that matches the underlying meaning of 
the message. In introducing abstract types, we have 
somehow managed to make our information format more precise 
and more opaque at the same time.

---------

## Unifying humans and computers

"We want to think like a human, but work like a machine" -
this is where parser generators, regexp come in. We write
in a DSL (or grammar) and it generates a low-level state
machine that makes the problem more like binary processing
under the hood (to some extent)

......


Show implementation in the context of a correct IRC logger.
(only focusing on PRIVMSG w. no prefix, on a particular channel)

USE BNF to construct a well-formed regexp. Talk step by step about
how to extract its patterns. Towards the end of this section,
discuss how instead of Regexp,
we could have used Racc (link to JSON article, or possibly
use the calculator example as one more section).

```
/[^ :\0\r\n]+/
```

```
/^:(.*) PRIVMSG (#
```

Formal specification of IRC messages:

```
Servers and clients send each other messages, which may or may not
generate a reply.  If the message contains a valid command, as
described in later sections, the client should expect a reply as
specified but it is not advised to wait forever for the reply; client
to server and server to server communication is essentially
asynchronous by nature.

Each IRC message may consist of up to three main parts: the prefix
(OPTIONAL), the command, and the command parameters (maximum of
fifteen (15)).  The prefix, command, and all parameters are separated
by one ASCII space character (0x20) each.

The presence of a prefix is indicated with a single leading ASCII
colon character (':', 0x3b), which MUST be the first character of the
message itself.  There MUST be NO gap (whitespace) between the colon
and the prefix.  The prefix is used by servers to indicate the true
origin of the message.  If the prefix is missing from the message, it
is assumed to have originated from the connection from which it was
received from.  Clients SHOULD NOT use a prefix when sending a
message; if they use one, the only valid prefix is the registered
nickname associated with the client.

The command MUST either be a valid IRC command or a three (3) digit
number represented in ASCII text.

IRC messages are always lines of characters terminated with a CR-LF
(Carriage Return - Line Feed) pair, and these messages SHALL NOT
exceed 512 characters in length, counting all characters including
the trailing CR-LF. Thus, there are 510 characters maximum allowed
for the command and its parameters.  There is no provision for
continuation of message lines.  See section 6 for more details about
current implementations.
```

From section 2.3.1:

```
The protocol messages must be extracted from the contiguous stream of
octets.  The current solution is to designate two characters, CR and
LF, as message separators.  Empty messages are silently ignored,
which permits use of the sequence CR-LF between messages without
extra problems.

The extracted message is parsed into the components <prefix>,
<command> and list of parameters (<params>).

The Augmented BNF representation for this is:

    message    =  [ ":" prefix SPACE ] command [ params ] crlf
    prefix     =  servername / ( nickname [ [ "!" user ] "@" host ] )
    command    =  1*letter / 3digit
    params     =  *14( SPACE middle ) [ SPACE ":" trailing ]
               =/ 14( SPACE middle ) [ SPACE [ ":" ] trailing ]

    nospcrlfcl =  %x01-09 / %x0B-0C / %x0E-1F / %x21-39 / %x3B-FF
                    ; any octet except NUL, CR, LF, " " and ":"
    middle     =  nospcrlfcl *( ":" / nospcrlfcl )
    trailing   =  *( ":" / " " / nospcrlfcl )

    SPACE      =  %x20        ; space character
    crlf       =  %x0D %x0A   ; "carriage return" "linefeed"

    letter     =  %x41-5A / %x61-7A       ; A-Z / a-z
    digit      =  %x30-39                 ; 0-9


NOTES:
  1) After extracting the parameter list, all parameters are equal
     whether matched by <middle> or <trailing>. <trailing> is just a
     syntactic trick to allow SPACE within the parameter.

  2) The NUL (%x00) character is not special in message framing, and
     basically could end up inside a parameter, but it would cause
     extra complexities in normal C string handling. Therefore, NUL
     is not allowed within messages
```

`PRIVMSG` handling:
http://tools.ietf.org/html/rfc2812#section-3.3.1

----------

JSON vs. MessagePack
Calc vs. JSON
MessagePack vs. BMP 
BMP vs. HTTP (metadata)
HTTP vs. LS
LS vs. IRC
IRC vs. MessagePack

(overkill but interesting?)

----

* Does the format tell you exactly where to look, or do you
need to scan the input data for separators?

* JSON and MessagePack express the same information (nearly 1-1) but
are processed in very different ways.

* JSON and Calculator example are processed in a very similar way,
but express completely different concepts.

* Binary formats are already "pre-processed" so you don't need to
do the intermediate tokenization / analysis with text formats.

* Binary files are optimized for computation, text files for humans.
BMP file will tell you exactly where the pixel array starts, but
in HTTP requests, you look for the implicit "\n\n". But in a
HTTP file you can directly use the body contents, whereas in
BMP you have to concern yourself with 4-byte padding.

* Explicit vs. implicit does not directly correspond to simple vs. complex.

## The anatomy of information formats

The job of any computer program is to convert seemingly meaningless sequences
of bytes into useful information.


## How do I get at the pixels?

Use headers to determine the size
and location of the pixel array, then
read this binary data:

```
00 00 FF
FF FF FF 
00 00 
FF 00 00 
00 FF 00 
00 00
```

## How do I get at the serialized hash structure?

Read the first byte to determine how to read the
next N bytes, rinse and repeat.

```
85 a1 61 01 a1 62 c3 a1 63 c2 
a1 64 c0 a3 65 67 67 cb 3f f5 
99 99 99 99 99 9a
```

Read this text file

```
{"a":1,"b":true,"c":false,"d":null,"egg":1.35}
```

## How do I get at the HTML file?

Make a HTTP request, then parse this response:

```
HTTP/1.1 200 OK
Content-Type: text/html
Content-Length: 146
Connection: close

<html>
  <body>
    <div style="text-align: center">
      <h1>Hello World!</h1>
      <img src="earth_heart.jpg" />
    </div>
  </body>
</html>
```

## How do I get at these files?

(Read them directly from disk, or make OS calls on them)
(Read metadata using OS calls)

## How do I get at these IRC messages?

Make a socket connection, run a few commands, then parse the
following line-based syntax:

```
:nick!~user@host-111-222-33-444.example.net PRIVMSG #testing :Hello Bot!
```

## How do I process these formulas?

Use a racc parser against each line from stdin

? (10 + (23 * 5)) / 52.0


------------------

Embedded metadata or external (or non-existent)?
Binary vs. Text
Flat vs. nested
Fixed vs. dynamic
Explicit vs. Derived

-----------------


Stream as a means to transport arbitrary types between unlike systems

Protocols and formats are typically meant to be universal, and so they are
language agnostic by design. To utilize them in Ruby, it's necessary to map
abstract concepts to Ruby structures.

The difficulty of processing information depends on how much metadata is
provided. In some cases, you're given everything you need directly in
the header section of a message. In other cases, some information
needs to be derived by applying calculations to simple values provided
in the metadata. And in many situations, you are not given any meaningful
metadata at all, and instead must implicitly piece together the structure
based on predetermined processing rules. (i.e. JSON { })

--------------

Syntactic structure
Types
Processing
State management

--------------

FILTERS

$ ls 
$ cat
MessagePack decoder
JSON decoder
BMP decoder

INTERACTIVE APPLICATIONS

Calc interpreter
HTTP
IRC

### $ ls (PIPELINE)

Input: A directory name or list of files (via shell expanded glob)
e.g. `somedir`, `somedir/*.txt` read from ARGV

Output: A formatted list of file names (and details) printed to STDOUT
(formatting depends on whether stream is redirected or not)

DATA: Files

### $ cat (PIPELINE)

Input: A file name or list of files (possibly via shell expanded glob)
e.g. `somedir`, `somedir/*.txt` read from ARGV

Output: A concatenated stream with the contents of all input files, and
possibly some extra transformations depending on the options (i.e. line numbers,
whitespace supression, etc.)  # important this is actually a stream, for
performance/efficiency reasons!

DATA: Files

### MessagePack decoder (ENDPOINT)

Input: Byte stream packed in MessagePack format

Output: (internal) only -- Ruby representation of the serialized data (nearly a
direct mapping)

DATA: Primitive structures (numbers, hashes, strings, arrays, etc.)

### JSON decoder (ENDPOINT)

Input: Text file in JSON format

Output: (internal) only -- Ruby representation of the serialized data (nearly a
direct mapping)

DATA: Primitive structures (numbers, hashes, strings, arrays, etc.)

### BMP decoder (ENDPOINT)

Input: Bytestream with BMP header and pixel array

Output: (internal) only --- Ruby representation of the pixel array

DATA: Pixels

### Calc interpreter (ENDPOINT / PIPELINE)

Input: Single-line formulas entered via STDIN

Output: Results of computations printed to STDOUT

(maybe show a POPEN interactive example?)

DATA: Arithmetic Formulas

### HTTP (DISTRIBUTED PIPELINE)

Input: (socket!) HTTP formatted request 
Output: (socket!) HTTP formatted response (split into header / body section)

In the most simple case, HTTP format is a simple key-value header format followed by raw body in response.

DATA: Files (remotely accessed)

### IRC Bot (DISTRIBUTED PIPELINE)

Input:  (socket) IRC Server commands / messages
Output: (socket) IRC client commands / messages

IRC is a simple line-based format (separated by \r\n), which makes it easy to parse.

(show format schema)

DATA: Chat messages, system commands

------------------------------------------------

* Direct mapping / Unix filter (ARGV): `ls`, `cat` \______ not sure this should be first or included at all
(note interesting issue w. glob expansion)         /

* Line-based flat grammar: IRC
* Document-based flat grammar: HTTP

* Compact Linear Binary Mapping : MessagePack

* Structured Binary Mapping: BMP

* Line-based nested grammar: Calculator  \____ Lines blur a bit.
* Document-based nested grammar: JSON    /

------------------------------------------------

Is it binary or text-based?
What separates the different fields in the data?
What metadata are we given (if any?)
Do we know how much data we need to read to extract the information we're
interested in? (i.e. do we know the size of the message?)
