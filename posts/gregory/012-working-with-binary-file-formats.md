Most of us enjoy Ruby because it allows us to express our thoughts without worrying too much about low-level computing concepts. With that in mind, it may come as a surprise that Ruby provides a number of tools specifically designed for making low-level computing easy. In this article we'll use a few of those tools to encode and decode binary files, demonstrating just how easy Ruby makes it to get down to the realm of bits and bytes.

In the examples that follow, we will be working with the bitmap image format. I chose this format because it has a simple structure and is well documented. Despite the fact that you'll probably never need to work with bitmap images at all in your day-to-day work, the concepts involved in both reading and writing a BMP file are pretty much the same as any other file format you'll encounter. For this reason, you're encouraged to focus on the techniques being demonstrated rather than the implementation details of the file format as you read through this article.

### The anatomy of a bitmap

A bitmap file consists of several sections of metadata followed by a pixel array that represents the color and position of every pixel in the image. 

While the information contained within a bitmap file is easy to process, its contents can appear cryptic due to the fact that the contents of the file get encoded as a non-textual sequence of bytes. The example below demonstrates that even if you break the sequence on its section and field boundaries, it would still be a real challenge to understand without any documentation handy:

```ruby
# coding: binary

hex_data = %w[
  42 4D 
  46 00 00 00 
  00 00 
  00 00 
  36 00 00 00

  28 00 00 00 
  02 00 00 00 
  02 00 00 00 
  01 00 
  18 00 
  00 00 00 00 
  10 00 00 00 
  13 0B 00 00 
  13 0B 00 00
  00 00 00 00 
  00 00 00 00

  00 00 FF
  FF FF FF 
  00 00 
  FF 00 00 
  00 FF 00 
  00 00
]

out = hex_data.each_with_object("") { |e,s| s << Integer("0x#{e}") }

File.binwrite("example1.bmp", out)
```

However, if you understand what each field is meant to represent, the values begin to make a whole lot more sense. For example, if you know that this is a 24-bit per pixel image that is two pixels wide, and two pixels high, you might be able to make sense of the pixel array data. Below I've listed the part of the file which represents that information so that you can take a closer look.

```
00 00 FF
FF FF FF 
00 00 
FF 00 00 
00 FF 00 
00 00
```

If you run the example script and open the image file, you will see something similar to what is shown below once you zoom in close enough to see the individual pixels:

<div align="center">
  <img src="http://i.imgur.com/XhKW1.png">
</div>

By experimenting a bit with changing some of the values in the pixel array by hand, you will fairly quickly discover the overall structure of the array and the way pixels are represented. After figuring this out, you might also be able to look back on the rest of the file and determine what a few of the fields in the headers are without looking at the documentation.

After exploring a bit on your own, you should check out the [field-by-field walkthrough of a 2x2 bitmap file](http://en.wikipedia.org/wiki/BMP_file_format#Example_1) that this example was based on. The information in that table is pretty much all you'll need to know in order to make sense of the bitmap reader and writer implementations I've built for this article.

### Encoding a bitmap image

Now that you've seen what a bitmap looks like in its raw form, I can demonstrate how to build a simple encoder object that allows you to generate bitmap images in a much more convenient way. In particular, I'm going to show what I did to get the following code to output the same image that we rendered via a raw sequence of bytes earlier.

```ruby
bmp = BMP::Writer.new(2,2)

bmp[0,0] = "ff0000"
bmp[1,0] = "00ff00"
bmp[0,1] = "0000ff"
bmp[1,1] = "ffffff"

bmp.save_as("example_generated.bmp")
```

Like most binary formats, the bitmap format has a tremendous amount of options that make building a complete implementation a whole lot more complex than just building something suitable for generating a single type of image. I realized shortly after skimming the format description that you can skip out on a lot of the semi-optional header data if you stick to 24bit-per-pixel images, so I decided to do exactly that.

Looking at the implementation from the outside-in, it's easy to see the general structure I laid out for the object. Pixels are stored as a boring array of arrays, and all the interesting things happen at the time you write the image out to file.

```ruby
class BMP 
  class Writer
    def initialize(width, height)
      @width, @height = width, height

      @pixels = Array.new(@height) { Array.new(@width) { "000000" } }
    end

    def [](x,y)
      @pixels[y][x]
    end

    def []=(x,y,value)
      @pixels[y][x] = value
    end

    def save_as(filename)
      File.open(filename, "wb") do |file|
        write_bmp_file_header(file)
        write_dib_header(file)
        write_pixel_array(file)
      end
    end

    # ... rest of implementation details omitted for now ...
  end
end
```

All bitmap files start out with the bitmap file header, which consists of the following things:

* A two character signature to indicate the file is a bitmap file (typically "BM").
* A 32bit unsigned little-endian integer representing the size of the file itself.
* A pair of 16bit unsigned little-endian integers reserved for application specific uses.
* A 32bit unsigned little-endian integer representing the offset to where the pixel array starts in the file.

The following code shows how `BMP::Writer` builds up this header and writes it to file:

```ruby
class BMP 
  class Writer
    PIXEL_ARRAY_OFFSET = 54
    BITS_PER_PIXEL     = 24

    # ... rest of code as before ...

    def write_bmp_file_header(file)
      file << ["BM", file_size, 0, 0, PIXEL_ARRAY_OFFSET].pack("A2Vv2V")
    end

    def file_size
      PIXEL_ARRAY_OFFSET + pixel_array_size 
    end

    def pixel_array_size
      ((BITS_PER_PIXEL*@width)/32.0).ceil*4*@height
    end
  end
end
```

Out of the five fields in this header, only the file size ended up being dynamic. I was able to treat the pixel array offset as a constant because we never need to include extra information beyond that what is included in the two fixed width headers that all bitmap files need. The [computations I used for the file size](http://en.wikipedia.org/wiki/BMP_file_format#Pixel_storage) are taken directly from wikipedia, and will make sense a bit later once we examine the way that the pixel array gets encoded.

The tool that makes it possible for us to convert these various field values into binary sequences in such a convenient way is `Array#pack`. If you note that the calculated file size of a 2x2 bitmap is 70, it becomes clear what `pack` is actually doing for us when we examine the byte by byte values in the following example:

```ruby
header = ["BM", 70, 0, 0, 54].pack("A2Vv2V") 
p header.bytes.map { |e| e.to_s(16).rjust(2,"0")  }

=begin expected output (NOTE: reformatted below for easier reading)
  ["42", "4d", 
   "46", "00", "00", "00", 
   "00", "00", 
   "00", "00", 
   "36", "00", "00", "00"]
=end
```
The sequence exactly matches that of our reference image, which indicates that the proper bitmap file header is being generated by this statement. This means that `Array#pack` is converting our Ruby strings and fixnums into their properly sized binary representations, in the format that we need them in. If we decompose the template string, it becomes easier to see where things line up:

```
  "A2" -> arbitrary binary string of width 2 (packs "BM" as: 42 4d)
  "V"  -> a 32bit unsigned little endian int (packs 70 as: 46 00 00 00)
  "v2" -> two 16bit unsigned little endian ints (packs 0, 0 as: 00 00 00 00)
  "V"  -> a 32bit unsigned little endian int (packs 54 as: 36 00 00 00)
```

While I went to the effort of expanding out the byte sequences to make it easier to see what is going on, you don't typically need to do this at all while working with `Array#pack`, provided that you craft your template strings carefully. Of course, some knowledge of the underlying binary data doesn't hurt, and our implementation of `write_dib_header` actually depends on it.

```ruby
class BMP 
  class Writer
    DIB_HEADER_SIZE    = 40
    PIXELS_PER_METER   = 2835 # 2835 pixels per meter is basically 72dpi

    # ... other code as before ...

   def write_dib_header(file)
      file << [DIB_HEADER_SIZE, @width, @height, 1, BITS_PER_PIXEL,
               0, pixel_array_size, PIXELS_PER_METER, PIXELS_PER_METER, 
               0, 0].pack("V3v2V6")
    end
  end
end
```

The DIB header itself is kind of boring, because we treat most of the fields as constants, and all the others are values that were already determined for use in the BMP file header. However, if you look closely at the file format description, you'll see that our pattern doesn't actually match the datatypes of some of the fields: width, height, and horizontal/vertical resolution are all specified as signed integers, but yet we're treating them as unsigned values. This was an intentional design decision, to work around a limitation of `pack` in Ruby versions earlier than 1.9.3.

The problem is that all versions of Ruby before 1.9.3, `Array#pack` does not provide a syntax for specifying the endianness of a signed integer. While encoding negative values as unsigned integers actually seems to produce the right byte sequences for a signed integer, I'm pretty sure that's an undefined behavior. What's worse: even if you do encode the binary sequences correctly, there is no way to extract them later without [resorting to weird hacks](http://stackoverflow.com/questions/5236059/unpack-signed-little-endian-in-ruby). With this in mind, I decided to take a closer look at the particular problem to see if I had any other options.

Even though the specification says that the dimensions and resolution of the image can be negative, I have no idea how that would ever be useful. It's also really unlikely that you'll have a value large enough to overflow back into negative numbers for any of these values. For this reason, it's safe to say that you can treat these values as unsigned integers without many consequences.  This is why I used the pattern `"V3v2V6"` without much fear of bad behavior. If I only cared about support Ruby 1.9.3, I could have used a different pattern which DOES take in account the endianness of signed integers: `Vl<2v2V2l<2V2"`. However, this is just trading one edge case for another, and since this is just a demo application, I went with what is more likely to work on the Ruby you're running right now.

With this weirdness out of the way, I was able to move on to working on the pixel array, which was relatively straightforward to implement.

```ruby
class BMP 
  class Writer
    # .. other code as before ...

    def write_pixel_array(file)
      @pixels.reverse_each do |row|
        row.each do |color|
          file << pixel_binstring(color)
        end

        file << row_padding
      end
    end

    def pixel_binstring(rgb_string)
      raise ArgumentError unless rgb_string =~ /\A\h{6}\z/
      [rgb_string].pack("h6")
    end

    def row_padding
      "\x0" * (@width % 4)
    end
  end
end
```

The most interesting thing to note about this code is that each row of pixels ends up getting padded with some null characters. This is to ensure that each row of pixels is aligned on WORD boundaries (4 byte sequences). This is a semi-arbitrary limitation that has to do with file storage constraints, but things like this are common in binary files. 

The calculations below show how much padding is needed to bring rows of various widths up to a multiple of 4, and explains how I derived the computation for the `row_padding` method:

```
Width 2 : 2 * 3 Bytes per pixel = 6 bytes  + 2 padding  = 8
Width 3 : 3 * 3 Bytes per pixel = 9 bytes  + 3 padding  = 12
Width 4 : 4 * 3 Bytes per pixel = 12 bytes + 0 padding  = 12
Width 5 : 5 * 3 Bytes per pixel = 15 bytes + 1 padding  = 16
Width 6 : 6 * 3 Bytes per pixel = 18 bytes + 2 padding  = 20
Width 7 : 7 * 3 Bytes per pixel = 21 bytes + 3 padding  = 24
...
```

Sometimes calculations like this are provided for you in the documentation, sometimes you need to derive them yourself. However, the deeply structured nature of most binary files makes this easy enough to do, especially if you apply some constraints to your implementation. For example, this computation would get a lot more complex if we allowed for an arbitrary amount of bits per pixel as the bitmap spec allows for.

While the padding code is definitely the most interesting aspect of the pixel array, there are a couple other details about this implementation worth discussing. In particular, we should take a closer look at the `pixel_binstring` method:

```ruby
def pixel_binstring(rgb_string)
  raise ArgumentError unless rgb_string =~ /\A\h{6}\z/
  [rgb_string].pack("h6")
end
```

This is the method that converts the values we set in the pixel array via lines like `bmp[0,0] = "ff0000"` into actual binary sequences. It starts by matching the string with a regex to ensure that the input string is a valid sequence of 6 hexidecimal digits. If the validation succeeds, it then packs those values into a binary sequences, creating a string with three bytes in it. The irb session below show make it clear what is going on here:

```
>> ["ffa0ff"].pack("h6").bytes.to_a
=> [255, 10, 255]
```

This makes it possible to specify color values directly in hexidecimal strings and then convert them to their numeric value just before they get written to the file.

And with this last detail explained, you should now understand how to build a functional bitmap encoder for writing 24bit color images. If seeing things step by step caused you to lose as sense of the big picture, you can check out the [full source code for this object](https://gist.github.com/1351737). Feel free to play around with it a bit before moving on to the next section: the best way to learn is to actually run these code samples and try to extend them and/or break them in various ways.

### Decoding a bitmap image

As you might expect, there is a nice symmetry between encoding and decoding binary files. To show just to what extent this is the case, I will walk you through the code which makes the following example run:

```ruby
bmp = BMP::Reader.new("example1.bmp")
p bmp.width  #=> 2
p bmp.height #=> 2

p bmp[0,0] #=> "ff0000"   
p bmp[1,0] #=> "00ff00" 
p bmp[0,1] #=> "0000ff" 
p bmp[1,1] #=> "ffffff" 
```

### Reflections
