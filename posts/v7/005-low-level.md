> This issue of Practicing Ruby was directly inspired by Nick Morgan's
> [Easy 6502](http://skilldrick.github.io/easy6502/) tutorial. While
> the Ruby code in this article is my own, the bytecode for the
> Snake6502 game was shamelessly stolen from Nick. Be sure to check
> out [Easy 6502](http://skilldrick.github.io/easy6502/) if this topic 
> interests you -- It's one of the best programming tutorials I've ever seen.

The sea of numbers you see below is about as close to the metal as programming gets:

```
0600: 20 06 06 20 38 06 20 0d 06 20 2a 06 60 a9 02 85 
0610: 02 a9 04 85 03 a9 11 85 10 a9 10 85 12 a9 0f 85 
0620: 14 a9 04 85 11 85 13 85 15 60 a5 fe 85 00 a5 fe 
0630: 29 03 18 69 02 85 01 60 20 4d 06 20 8d 06 20 c3 
0640: 06 20 19 07 20 20 07 20 2d 07 4c 38 06 a5 ff c9 
0650: 77 f0 0d c9 64 f0 14 c9 73 f0 1b c9 61 f0 22 60 
0660: a9 04 24 02 d0 26 a9 01 85 02 60 a9 08 24 02 d0 
0670: 1b a9 02 85 02 60 a9 01 24 02 d0 10 a9 04 85 02 
0680: 60 a9 02 24 02 d0 05 a9 08 85 02 60 60 20 94 06 
0690: 20 a8 06 60 a5 00 c5 10 d0 0d a5 01 c5 11 d0 07 
06a0: e6 03 e6 03 20 2a 06 60 a2 02 b5 10 c5 10 d0 06 
06b0: b5 11 c5 11 f0 09 e8 e8 e4 03 f0 06 4c aa 06 4c 
06c0: 35 07 60 a6 03 ca 8a b5 10 95 12 ca 10 f9 a5 02 
06d0: 4a b0 09 4a b0 19 4a b0 1f 4a b0 2f a5 10 38 e9 
06e0: 20 85 10 90 01 60 c6 11 a9 01 c5 11 f0 28 60 e6 
06f0: 10 a9 1f 24 10 f0 1f 60 a5 10 18 69 20 85 10 b0 
0700: 01 60 e6 11 a9 06 c5 11 f0 0c 60 c6 10 a5 10 29 
0710: 1f c9 1f f0 01 60 4c 35 07 a0 00 a5 fe 91 00 60 
0720: a2 00 a9 01 81 10 a6 03 a9 00 81 10 60 a2 00 ea 
0730: ea ca d0 fb 60 
```

Although you probably can't tell by looking at it, what you see here
is assembled machine code for the venerable 6502 processor that powered 
many of the classic video games of the 1980s. When executed in simulated
environment, this small set of cryptic instructions produces a minimal
version of the Snake arcade game, as shown below:

![](http://i.imgur.com/0DsKeoy.gif)

In this article I will show you how build a stripped down 6502 simulator 
in JRuby that is complete enough to play this game. But there is a catch:
we won't discuss much about specific 6502 instructions until the very 
end of the article, and we will barely touch on how the game 
itself is implemented. Instead, our goal will be to develop a conceptual
understanding of low-level computing from the bottom up.

### Roadmap

* Storage (random access, indexed access, flow control, stack, program) 
* CPU ( registers, flags )
* Visualization ( pixels, colors )

* MemoryMap ( randomizer, keyboard input, pixel array )
* Reference ( addressing modes )

* Config (DSL loader, CSV mapping)
* Simulator (Program loop)

### DSL / Code mappings

If we take a few of the games instructions and annotate them with
their equivalent assembly code and some comments, things immediately
become a whole lot more understandable:

```
$064d    a5 ff     LDA $ff      # read the last key pressed on the keyboard
$064f    c9 77     CMP #$77     # check if the key was "w" (ASCII code 0x77)
$0651    f0 0d     BEQ $0660    # if so, jump forward to $0660 
$0653    c9 64     CMP #$64     # check if the key was "d" (ASCII code 0x64)
$0655    f0 14     BEQ $066b    # if so, jump forward to $066b
$0657    c9 73     CMP #$73     # check if the key was "s" (ASCII code 0x73)
$0659    f0 1b     BEQ $0676    # if so, jump forward to $0676
$065b    c9 61     CMP #$61     # check if the key was "a" (ASCII code 0x61)
$065d    f0 22     BEQ $0681    # if so, jump forward to $0681
```
