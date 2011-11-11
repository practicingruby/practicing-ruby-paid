Automated testing is tremendously useful, but is not something to obsess over.  Too many people spread dogmatic views about testing, and many others feel guilty about not living up to the rigid expectations set by TDD purists. We have collectively generated more heat than light when it comes to testing, and I think it's about time for us to change our perspective a little bit.

In this article, I have collected my thoughts on what I feel is more pragmatic approach to testing that doesn't need to carry the label of "Test Driven Development" and its associated baggage. My goal is to lay out a middle-of-the-road path for those who want to experience many of the benefits of automated testing without feeling boxed in by rigid and excessively formal methodologies. But before I can do that, I need to point out some of the things that people tend to get tripped up on which make getting started with testing harder than it needs to be.

## Things that don't matter as much as they seem

SEGUE

### Choosing the best testing framework

While there are a ton of frameworks out there, odds are you will end up using some combination of Test::Unit, RSpec, and MiniTest for most or all of your Ruby projects. Each of these frameworks has its pros and cons, but each is also well supported. RSpec has more functionality built into its core, but extensions exist for Test::Unit and MiniTest to give you pretty much everything RSpec has to offer. The question is mainly whether you want to start with everything available to you at the cost of some complexity, or whether you want to start with a simple tool at the cost of having to search for some add-ons later.

My personal preference is to use [MiniTest::Spec](http://www.rubyinside.com/a-minitestspec-tutorial-elegant-spec-style-testing-that-comes-with-ruby-5354.html) when possible, because it has some of the niceties of RSpec but is very much stripped down to the metal and its codebase can be read in a single setting. But I've worked on projects where RSpec was used effectively, and also wrote a ton of Test::Unit tests before Ruby 1.9 was widely accepted. My efficiency in writing tests was about the same in all three frameworks, with the exception that I burned extra cycles on RSpec due to it being updated and changed often while I was working with it. However, RSpec 2.x is an entirely different world than RSpec 1.x, and now I imagine those problems have gone away.

As long as you are working with at least one of these three frameworks, you're going to be fine. If you aren't working with any of them, just make sure you have a good reason for swimming against the stream that holds up to peer review.

### Writing tests before writing implementation code



### Having 100% code coverage

### Adopting a "mockist" testing strategy

### Using formal user stories and/or a story runner

## Things that matter in (almost) every project

------------------------------------------------

### Building a good set of examples and seed data

### Following SOLID design principles

### Testing bug fixes

### Testing business logic / algorithms

### Testing critical paths

### Testing core building blocks

### Mention in conclusion "Test first or test later", "Test::Unit, MiniTest, RSpec"

--------------------------------------------------


## Things that matter after your code ships

### Full test coverage for new features or non-trivial changes to existing features

### Sufficient test coverage for any non-trivial refactoring

### Cleanup and removal of stale or obsolete tests

---------------


## The middle path to automated testing

### Get some formal TDD experience under your belt

You won't know what you can flex on and what you can't without experiencing the full test first experience. You won't know what pitfalls to look out for when it comes to under testing or over testing if you don't drink at least some of the kool-aid.

It's important to get back into this flow from time to time, but you can definitely pick and choose the projects you use it on. You don't HAVE to write test first all the time, and some projects may not need tests at all. 

Writing tests first works best for me on fairly well defined problems. If the solution is obvious, TDD gives me a nice, clean path to it. But if I'm not sure what the *right problem* is to solve, or whether my app will be a success, I prefer doing spikes and layering in tests once things stabilize more.

### Write tests to verify your bug fixes

A minimum defect-reproducing example is already very close to being a unit test. Formalizing it makes it possible to safeguard against this issue recurring.

### Write tests to verify algorithmic results

It's not likely that the way to validate the checksum on an EAN13 is going to change any time soon, so tests around it are likely to make it very easy to spot unexpected regressions. Virtually all well defined algorithmic problems are ideal candidates for automated testing, and make for easy TDD as well.

### Write tests for your critical features

The most used features, or most important ones, should be well tested so that one can afford to make changes to the app without being paranoid of breaking something on the critical path. Example: Payment processing is critical, but some reporting feature may not be.

-----

### Write good examples that show how your system is used

Writing good examples serves as an informal way to do integration testing. A bit more direct than something like cucumber stories, with direct value outside of the test suite.

Examples drive what objects and functions need to be created, and provide a good jumping off point for TDD.

### Use the SOLID principles to design for testability

A benefit of tests is that they can help improve software design. But really, it's possible to get these benefits without writing tests first. Following the SOLID principles will pretty much ensure your code will be easily testable down the line. Understanding the core design principles and being able to apply them is a more important skill than TDD itself.

------


### Minimize the amount of mocks used

Mocks are complicated to maintain, and remove the secondary benefit of unit tests doubling as integration tests of your internals. Limit the use of mocks to the following things: 1) external resources 2) highly performance intensive tasks 3) very hard to set up resources. Try to couple anything mocked with real tests that are run on demand.

### Building Blocks should be tested

If there are some features in your application that many other feautures depend on, those should be given priority when introducing tests. It's a bad idea to build on top of untested code. Testing these dependencies indirectly can work (i.e. writing tests at the higher level), but writing tests at the level of the dependency helps catch trivial issues with it that will cause it to break contract or cause far reaching bugs.

### Don't do heavy refactoring without sufficient test coverage

Certain simple refactorings can be done without test coverage, but most refactorings are much easier to pull off with a safety net. At a minimum, tests should exist at the interaction points between collaborators, so that immediate effects of refactoring can be detected and dealt with.

### Continuously assess the value of testing

If many people are working on a program, tests make it possible to work on one area of a project without necessarily understanding the whole system. Tests also serve as good documentation of intent, making it possible for new collaborators to get comfortable faster.

Similar benefits exist for long-running projects. Even a single developer will begin to view old parts of the system as legacy code late into the process, and the benefits regarding protection against ignorance about how certain aspects of the system work, as well as the documentation value of tests apply once again.

The moral of the story is that tests are much more valuable in a long-running,
multi-developer project than they are in an adhoc reporting script or simple
prototype. This means your investment in testing should be evaluated
accordingly.

### Be aware of test maintenance costs, and examine the cost of not testing

Writing tests is a lot of work, and getting full coverage is hard. Whenever you're investing time into testing, think about the cost of leaving the tests out in the worst-case, best-case, and average case scenario. Sometimes the right decision is to cover the critical path but leave some low impact features untested if they're difficult to cover. Sometimes it makes sense to write tests no matter how much work it is.

Don't treat your tests as a write-once, run forever entity. Good test suites require active maintenance, and you shouldn't be afraid to delete or change tests as your application evolves.

### You can mix modes by keeping full coverage on master while allowing testless spikes on branch

It's safe to play around on feature branches before committing to writing tests. Just have a good policy in place for post-production applications that anything that gets merged into the main line comes with tests, or is obviously not going to interfere with critical operations.

### Use MiniTest::Spec if possible

MiniTest is in the Ruby standard library, so it "just works". Moreover, it is trivial to understand the entire library inside and out with just a small amount of code reading. RSpec is very powerful (and incredibly featureful), but its complexity along with the tools around it give testing too much emphasis. You don't need RSpec unless you *want* to be test obsessed. 