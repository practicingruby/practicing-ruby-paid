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

Like most binary formats, the bitmap format has a tremendous amount of options that make building a complete implementation a whole lot more complex than just building something suitable for generating a single type of image. I realized shortly after skimming the format description that you can skip out on a lot of the semi-optional header data if you stick to 24bit-per-pixel images, and so I decided to start there.

Working backwards from the example file, I found that I would need to study the bitmap file header as well as the device independent bitmap header. I started with exploring the bitmap file header because it was the more straightforward of the two.

The file header starts with a magic number which is meant to indicate to decoders that the file is a bitmap file. While there are several valid values for this number, most of them are OS/2 related and virtually all common uses of bitmaps are in the Windows format. This means that almost all the bitmaps you'll encounter start off with the identifier which represents the windows format, "BM". This explains why the raw code of the bitmap we looked at earlier started with `42 4D` as its hex values. 

```
>> 0x42.chr
=> "B"
>> 0x4D.chr
=> "M"
```

The next field in the file header is an integer that indicates the size of the file itself. This may sound a bit like a circular reference, but due to the highly structured nature of most binary file formats, this number can usually be computed easily. I was able to find the [computations I needed](http://en.wikipedia.org/wiki/BMP_file_format#Pixel_storage) by briefly skimming the wikipedia article. Because these computations depend only on the number of bits per pixel and the dimensions of the image, it was easy to write a function which computes the file size.

```ruby
class BMP 
  class Writer
    PIXEL_ARRAY_OFFSET = 54
    BITS_PER_PIXEL     = 24

    def initialize(width, height)
      @width, @height = width, height
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

After I wrote this code I was able to verify that the calculated file size matched the real file size of the sample file, as shown below.

```ruby
bmp = BMP::Writer.new(2,2)
p bmp.file_size #=> 70

p File.size("example1.bmp") #=> 70
```

To see how this number relates to the binary sequence in the raw bitmap file, we simply need to convert the decimal number `70` to its hexidecimal representation:

```ruby
>> 70.to_s(16)
=> "46"
```

While this number is small enough to fit in a single byte, larger images would have larger file sizes and so the bitmap format reserves four bytes worth of space for the integer representing the file size. If we look at this field in the raw BMP file, we see `46 00 00 00`. It's worth mentioning that this is exactly how the decimal number 70 gets represented as a 32bit little-endian unsigned integer, buts it's safe for you to ignore the details for now if that isn't immediately obvious to you. 

The file size field is followed by two fields which are reserved for use by the application which generates the bitmap file. This kind of reserved field is common in binary files, and typically are safe to ignore. This explains why the third and fourth field in the sample file are set to `00 00`.


### Decoding a bitmap image


### Reflections
