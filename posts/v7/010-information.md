> CREDIT: GEB.

Start with a story about what happens when I type a message into an
IRC channel, and how it gets to you. (Sockets, IRC protocol,
client->server->client etc).

LOOKING AT DIFFERENT WAYS TO STORE, PROCESS, REPRESENT, AND INTERPRET
A SINGLE SIMPLE MESSAGE.

---

## Where we see the forest, the computer sees only trees 

**FIXME CONNECTING PARAGRAPH**

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

## The meaning of a message depends on its level of abstraction

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

## Every expressive syntax has at least a few corner cases

Consider once more our fascinating Ruby array:

```ruby
["PRIVMSG", "#practicing-ruby-testing", "Seasons greetings to you all!"]
```

We've seen that because its structure is highly generic, its
encoding rules are very permissive. Nearly any sequence of
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

## What happens if we get rid of syntax entirely?

> Discusses bypassing syntax entirely as a means of overcoming syntactic
restrictions / corner cases.

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

## Solving the conceptual mapping problem via abstract types

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

## Combining human intuition with computational rigor 

> Discusses formalizing syntax rules to allow for human
readability without sacrificing precision.

As we explored the MessagePack format, we saw that by coming up with very
precise rules for processing an input stream, we can interpet messages by
running a series of simple and unambiguous computations. But in the
process of making things easier for the computer, we complicated
things for humans. Try as we might, we aren't very good at
rapidly extracting meaning from numeric sequences like
`93`, `C7 01 07`, `C7 02 18`, and `C7 03 1D`.

So now we've come full circle in our explorations, realizing that we really do
want to express ourselves using something like the text-based IRC message 
format. Let's look at it one last time to reflect on its strengths
and weaknesses:

```ruby
"PRIVMSG #practicing-ruby-testing :Seasons greetings to you all!\r\n"
```

The main feature of representing our message this way is that because we're
familiar with the cocept of *commands* as programmers, it is easy to see
the structure of the message without even worrying about its exact syntax 
rules: we know intuitively that `PRIVMSG` is the command being sent,
and that `#practicing-ruby-testing` and `Seasons greetings to you all!`
are its parameters. From here, it's easy to extract the underlying
meaning of the message, which is: "Send the message 'Seasons greetings to you
all!' to the #practicing-ruby-testing channel".

The drawback is that we're hazy on the details: we can't simply guess the rules
about whitespace in parameters, and we don't know exactly how to interpret 
the `:` character or the `\r\n` at the end of the message. Because a correct 
implementation of the IRC protocol will need to consider
various edge cases, attempting to precisely describe the message format
verbally is challenging. That said, we could certainly give
it a try, and see what happens...

* Messages consist of a valid IRC command and its parameters
(if any), followed by `\r\n`.

* Commands are either made up solely of letters, or are
represented as a three digit number.

* All parameters are separated by a single space character.

* Parameters may not contain `\r\n` or the null character (`\0`).

* All parameters except for the last parameter must not contain
spaces and must not start with a `:` character.

* If the last parameter contains spaces or starts with a `:`
character, it must be separated from the rest of the
parameters by a `:` character, unless there are exactly
15 parameters in the message. 

* When all 15 parameters are present, then the separating `:` 
character can be omitted, even if the final parameter
includes spaces.

This ruleset isn't even a complete specification of the message format, 
but it should be enough to show you how specifications written in
prose can quickly devolve into the kind of writing you might expect 
from a tax attorney. Because spoken language is inherently fuzzy and 
subjective in nature, it makes it hard to be both precise and 
understandable at the same time.

To get around these communication barriers, computer scientists
have come up with *metalanguages* to describe the syntactic rules
of protocols and formats. By using precise notation with well-defined 
rules, it is possible to describe a grammar in a way that is both
human readable and computationally unambiguous.

When we look at the real specification for the IRC message format,
we see one of these metalanguages in. Below
you'll see a nearly complete specification[^1] for the general form
of IRC messages expressed in [Augmented Backus–Naur Form][ABNF]:

```
message    =  command [ params ] crlf
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
```

If you aren't used to reading formal grammar notations, this example may appear
to be a bit opaque at first glance. But if you go back and look at the
rules we listed out in prose above, you'll find that all of them are expressed
here in a way that leaves far less to the imagination. Each rule tells us
exactly what should be read from the input stream, and in what order.

Representing syntactic rules this way allows us to clearly understand
their intended meaning, but that's not the only reason for the formality. 
BNF-based grammar notations express syntactic rules so precisely that we can 
use them not just as a specification for how to build a parser
by hand, but as input data for a parser generator that can build
a highly optimized parser for us. This not only saves development effort,
it also reduces the likelihood that some obscure edge case will be
"lost in translation" when converting grammar rules into raw
processing code.

To give a practical example of this technique in use, I converted the
ABNF representation of the IRC message format into a grammar that is 
readable by the Citrus parser generator. Apart from a few lines of 
embedded Ruby code used to transform the input data, it should look 
conceptually similar to what you saw above:

```
grammar IRC
  rule message
    (command params? endline) {
      { :command => capture(:command).value,
        :params  => capture(:params).value }
    }
  end

  rule command
    letters | three_digit_code 
  end

  rule params
    ( ((space middle)14*14 (space ":"? trailing)?) |
      ((space middle)*14 (space ":" trailing)?) ) {
      captures.fetch(:middle, []) + captures.fetch(:trailing, [])
    }
  end

  rule middle
    non_special (non_special | ":")*
  end

  rule trailing
    (non_special | space | ":")+
  end

  rule letters
    [a-zA-Z]+
  end

  rule three_digit_code
    /\d{3}/ { to_str.to_i }
  end

  rule non_special
    [^\0:\r\n ]
  end

  rule space
    " "
  end

  rule endline
    "\r\n"
  end
end
```

Loading this grammar into Citrus, we end up with a parser that can correctly
extract the commands and paramaters from our original `PRIVMSG` example:

```ruby
require 'citrus'
Citrus.load('irc')

msg = "PRIVMSG #practicing-ruby-testing :Seasons greetings to you all!\r\n"

data = IRC.parse(msg).value

p data[:command] 
#=> "PRIVMSG"

p data[:params]
#=> ["#practicing-ruby-testing", "Seasons greetings to you all!"]
```

CONNECTING PARAGRAPH HERE

## FIXME SUMMARY SECTION NAME

Nothing inherently wrong w. naive approach... Could have just done this:

```ruby
msg = "PRIVMSG #practicing-ruby-testing :Seasons greetings to you all!\r\n"

data = msg.match(/PRIVMSG (?<channel>.*) :(?<body>.*)\r\n/)

p data[:channel]
p data[:body]
```

we discover why something like C7 01 08 can be useful, or why placing a seemingly arbitrary : character in a string can make all the difference.
We see the structures beneath the syntax and feel their similarities and differences. 


----

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

[ABNF]: http://en.wikipedia.org/wiki/Augmented_Backus%E2%80%93Naur_Form
[^1]: For the sake of simplicity, I omitted the optional prefix which contains information about the sender of a message, because it involves somewhat complicated URI parsing. See [page 7 of the IRC specfication](http://tools.ietf.org/html/rfc2812#page-7) for details.
