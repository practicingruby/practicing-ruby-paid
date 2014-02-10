
The typical open source project is a long-term effort with an open-ended scope and a distributed development team made up of volunteers. In this kind of environment, focusing on quality is a matter of practicality, not pride.

Quality matters because high quality code is easy to understand, easy to change, and easy to reuse. For those reasons, a project consisting mostly of good code will be easy to contribute to, easy to maintain, and easy to extend to meet a wide variety of use cases. This is the ideal we all strive for, but it is difficult to maintain consistently in practice.

As projects mature, their internals often get worse rather than better as their external capabilities expand. Features become less stable as interactions between low-level components get increasingly complex and mistaken assumptions permeate throughout the system. As bad code accumulates, it becomes difficult to improve one part of a system without breaking something else in the process. This is the point where open source projects start to become more trouble than they are worth, and people set out in search of greener pastures.

Not all projects need to end up this way, though. As long as you can manage to keep the quality arrow pointing upwards over the long haul without burning yourself out, the bad code you've accumulated over time won't prevent you from gradually replacing it with better code. Because code quality often declines due to poor maintenance practices rather than a lack of technical skills, reversing this trend is as easy as improving the way a project is maintained.

In this article, we'll discuss three specific tactics we've used in our own projects that can be applied at any stage in the software development lifecycle. These are not quick fixes; they are helpful habits that pay off more and more as you continue to practice them. The good news is that even though it might be challenging to keep up with these efforts on a daily basis, the recommendations themselves are very simple:

1. Let external changes drive internal quality improvements
2. Treat all code with inadequate testing as legacy code
3. Favor adding new extension points over new features

We'll now take a look at each of these techniques individually and walk you through some examples of how we've put them 
into practice in RDoc, RubyGems, and Prawn -- three projects that have had their own share of quality issues over 
the years, but continue to serve very diverse communities
of users and contributors.  

### 1) Let external changes drive internal quality improvements

This is not a particularly well-factored method.

```ruby
def build_image_object(file)
  # ... I/O DUCK TYPING GUARDS ...
  file.rewind  if file.respond_to?(:rewind)
  file.binmode if file.respond_to?(:binmode)

  if file.respond_to?(:read)
    image_content = file.read
  else
    raise ArgumentError, "#{file} not found" unless File.file?(file)  
    image_content = File.binread(file)
  end
  
  # ... EVERYTHING ELSE ...
  image_sha1 = Digest::SHA1.hexdigest(image_content)

  if image_registry[image_sha1]
    info = image_registry[image_sha1][:info]
    image_obj = image_registry[image_sha1][:obj]
  else
    info = Prawn.image_handler.find(image_content).new(image_content)

    min_version(info.min_pdf_version) if info.respond_to?(:min_pdf_version)

    image_obj = info.build_pdf_object(self)
    image_registry[image_sha1] = {:obj => image_obj, :info => info}
  end

  [image_obj, info]
end
```

Extract the I/O-related test into a helper method before changing their
behavior:

```ruby
def build_image_object(file)
  # ... Call a helper to perform I/O guards ...
  io = verify_and_open_image(file)
  image_content = io.read

  # ... Everything else stays the same ... 
end
```

Then revise the code to support the new behavior.

```ruby
def verify_and_open_image(io_or_path)
  if io_or_path.respond_to?(:rewind)
    io = io_or_path

    io.rewind

    io.binmode if io.respond_to?(:binmode)
    return io
  end

  io_or_path = Pathname.new(io_or_path)
  raise ArgumentError, "#{io_or_path} not found" unless io_or_path.file?
  
  io_or_path.open('rb')
end
```

Even though we had tests in Prawn that covered using `Pathname` objects, they
only verified the behavior at the level of Prawn's object model, and not at the
PDF output level. We have a low-level way of testing the PDF format, but it
would be tedious to write tests directly using it. For this reason, Matt added
an rspec to make that kind of tester easier:

```ruby
RSpec::Matchers.define :have_parseable_xobjects do
  match do |actual|
    expect { PDF::Inspector::XObject.analyze(actual.render) }.not_to raise_error
    true
  end
  failure_message_for_should do |actual|
    "expected that #{actual}'s XObjects could be successfully parsed"
  end
end
```

Finally, he provides a few test cases to demonstrate that his patch works 
as expected:

```ruby
context "setting the length of the bytestream" do
  it "should correctly work with images from Pathname objects" do
    info = @pdf.image(Pathname.new(@filename))
    expect(@pdf).to have_parseable_xobjects
  end

  it "should correctly work with images from IO objects" do
    info = @pdf.image(File.open(@filename, 'rb'))
    expect(@pdf).to have_parseable_xobjects
  end

  it "should correctly work with images from IO objects not set to mode rb" do
    info = @pdf.image(File.open(@filename, 'r'))
    expect(@pdf).to have_parseable_xobjects
  end
end
```

Putting all this together we see that in the span of a single bug fix, we also
gained the following benefits:

* The `build_image_object` method is more understandable because one of its
responsibilities has been broken out into its own method.

* The `verify_and_open_image` method allows us to group together all the
basic guard clauses for determining how to process the I/O-like object in
one place, making it easier to see exactly what those rules are.

* The added tests clarify the intended behavior of our image support.

* The additional test helper makes it possible for us to more easily do
PDF-level tests for corrupted output in the future.

None of this required a specific and focused effort of refactoring or redesign,
it just required paying attention to what the pain points were surrounding the
change to be made, and some consideration of what the future maintenance costs
of the feature would be.

### 2) Treat all code without adequate testing as legacy code

Historically, we've defined legacy code as code that was written long before our time, without any consideration for our current needs. However, any code without adequate test coverage can also be considered legacy code[^1], because it often has many of the same characteristics that make outdated systems difficult to work with. Open source projects evolve quickly, and even very clean code eventually decays if its desired behavior is never formally specified.

To guard against the negative impacts of legacy code, it is necessary to continuously grow and maintain your project's automated test suite so that it constantly reflects your current understanding of the problem domain you are 
working in. A good starting point is to make sure that your project has good code coverage and that you keep your builds green in CI, but once you've done that you need to go beyond the idea of just having lots of tests and focus on the
overall quality of your test suite.

A good time to look for opportunities to improve the quality of your test suite is whenever some new feature or fix is about to be merged. In particular, the following guidelines  can be helpful when considering new change requests:

* When reviewing a pull request, check to make sure that new behavior has tests, and that they are written precisely enough that you will understand them several months from now. If anything is unclear, discuss it with the submitter and then add additional specs to cover the assumptions.

* Also look to see whether the code depends on existing features that either do not have tests, or have tests that are underspecified. In most cases, adding additional test coverage one layer out will help prevent you from seeing a higher level feature and not understanding why when a low-level feature changes in some subtle way.

* Be extra wary of changes to existing features. Even if the change is covered by tests, the base behavior may not be adequately covered.

* If bugs or bad behaviors are encountered in collaborating objects while working on integrating a new feature, add tests for those as well. This will help prevent regressions from slipping back into your system from a different entry point.

* If the change is a bugfix itself, make sure that it captures the bug at the actual level it is happening at, and not just at the surface level. Usually it makes sense to add a test at two levels: the level it was discovered at, and at the source of the problem. But if you choose only one, pick the source level.

* For a bug fix, create reproducing examples by stripping away layers until you can no longer reproduce an incorrect behavior. Then clarify the correct behavior at that level.

* For a feature, make sure that use cases are clearly defined, if not in the tests then at least in the pull request discussion or an example file. These will help you interpret the intention behind the tests, rather than just the assertions. Augment the specs with any clarifications as needed.

* Even if a pull requests has tests of its own and the full suite passes, is it built on top of code that is poorly tested? If so, there may be built in assumptions that are invalid. Helps to at least push the wall back one level out.

* Try to educate contributors about your process and how to make future pull requests go more smoothly, but don't expect them to do your maintenance work for you.

**Examples from our projects**

(Maybe add more complicated ones, too? -- especially ones where the test isn't
good enough)

https://github.com/rubygems/rubygems/pull/781

### 3) Favor adding new extension points over new features

19:07 <seacreature> Nice. So another reason to have an extension API beyond external use is to make internals more
                    pluggable / replaceable too. In the case of something like RDoc this is as good of a reason to use
                    them as potential third-party benefits. Do you agree?
19:07 <seacreature> It also separates the parts of the system that change independently of one another from those that
                    need to change all at once.
19:10 <drbrain> yes
19:10 <drbrain> I added a bunch of stuff to kick out rdoc-chm
19:11 <seacreature> I want to be able to emphasize this this aspect of things because I think people often consider
                    plugin systems t o be primarily about third party additions
19:13 <seacreature> but the ability to move things in and out of core gracefully is an underappreciated maintenance
                    benefit
19:13 <drbrain> definitely
19:14 <drbrain> also, with a plugin system more people touch more of your code meaning you have to make everything
                better


RDoc wiki example... use it to create github issue links?

(RDoc examples)
(prawn-templates)
(extension points)

[^1]: The definition of legacy code as code without tests was popularized in 2004 by Michael Feathers, author of the extremely useful [Working Effectively with Legacy Code](http://www.amazon.com/Working-Effectively-Legacy-Michael-Feathers/dp/0131177052) book.

