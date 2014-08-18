## The structure and meaning of formats and protocols

The job of any computer program is to convert seemingly meaningless sequences
of bytes into useful information.



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
