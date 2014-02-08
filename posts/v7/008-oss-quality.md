
The need for high quality standards in open-source projects is a matter of practicality, not pride. To understand why, it helps to remember that "bad code" is often hard to understand, hard to test, hard to change, and hard to reuse. In turn, a project that depends on lots of poor quality code will end up being painful to contribute to, painful to maintain, and painful to use. To put it bluntly: poor quality open source projects can end up causing more trouble than they're worth for everyone involved with them.
 
Does this mean that only people with amazing coding skills should work on open source projects? Absolutely not! In most cases, quality issues in open source projects stem from a lack of a well-balanced maintenance process rather than a lack of technical competence. In other words, it pays to assume that some amount of chaos is endemic to open source software development, and that we just need to learn how to manage it better.

An optimal development process is one that always keep the quality arrow pointing upwards over the long haul, but isn't so brittle as to prevent the occasional mistake from happening. In this article, we'll share a few techniques for maintaining high quality standards without assuming that everything will always work out as planned, and without assuming that every contributor knows as much about your project as you do.

There are many ways to improve open source software quality, but our recommendations boil down to three simple ideas that we already use in our own projects:

1. Let external changes drive internal quality improvements
2. Treat all code with inadequate testing as legacy code
3. Favor extension points over features

We'll now take a look at each of these techniques individually and walk you through some examples of how we've put them 
into practice in RDoc, RubyGems, and Prawn.  

### 1) Let external changes drive internal quality improvements

Attempting to deal with each and every pain point that exists in your project will eat away at energy that would be better spent moving it forward, warts and all. Because there will always be rough patches in your codebase, it pays to focus only on the ones that are having the most impact on the project as a whole.

To keep a project stable as it grows, it is sufficient to simply focus on improving quality wherever people are actively working in the codebase. This is something that can be done a little at a time, and it can be done without taking too much effort away from producing valuable user-facing changes. Taking this approach makes it so that you don't need to explicitly schedule time to rewrite entire functions, classes, and subsystems. All that matters is that you leave your codebase a little better off whenever you set out to do some work.

If the effort you spend on code cleanup is proportional to the amount of pain that bad code is causing you, the problematic areas of your project's codebase will gradually break up into smaller and smaller chunk. Eventually it will becomes easy to make many kinds of meaningful change without bad code getting in the way. This process does take time though, so a bit 
of patience will go a long way.

Incremental quality improvements won't make you feel like a hero in the way that a highly focused cleanup effort might, 
but they are much more efficient over the long haul for two reasons: they require a much smaller initial investment, and they allows you to benefit from any knowledge gained over time as your project continues to evolve. Unlike large-scale efforts, incremental improvements also hold no risk of being abandoned because they don't stay in a work-in-progress state for long.

**Examples of incremental quality improvements**

https://github.com/prawnpdf/prawn/issues/570

https://github.com/prawnpdf/prawn/pull/579 (complicated)

(legacy article for a MUCH longer example)

### 2) Treat all code without adequate testing as legacy code

Historically, we've defined legacy code as code that was written long before our time, without any consideration for our current needs. However, any code without adequate test coverage can also be considered legacy code[^1], because it often has many of the same characteristics that make outdated systems difficult to work with.

The lifecycle of an open source project is effectively infinite and the scope of its problem domain is often left open-ended, and that means that most maintainers see their fair share of both antiquated and poorly tested code. Knowing how to work skillfully with legacy code in a project and can go a long way towards raising overall quality and maintainability.

The most direct way to guard against the negative impacts of legacy code is to keep growing and maintaining your project's automated test suite so that it constantly reflects your current understanding of the problem domain you are 
working in, along with any formal assumptions you have about how your code is meant to be used. These goals cannot be met solely by having good code coverage and keeping the build
green in CI, but that may be a good place to start if you aren't already at that level with your testing setup. 

The best place to look for opportunities to improve the quality of your test suite is whenever some new feature or fix is about to be merged. In particular, the following guidelines  can be helpful when considering new change requests:

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

### 3) Favor extension points over features

Although clients are likely to change thoseeir mind and product companies are
likely to change their vision, they do not deal with the same challenges of
open-source, which is that the potential scope of what people will use your code
for is effectively infinite.

When someone wants to add a new non-critical feature or rethink an existing one,
encourage them to build it as an extension first. Provide the necessary support
and improve your extension points whenever it is reasonable to do so (but beware
the rule of 3).

Make use of your own extension points internally so that all extension points
already have once consumer. This also makes your testing easier, and decreases
the likelihood that you will break external extensions accidentally.

Doing this greatly reduces your own maintenance responsibilities, and allows
both the extraction of unstable / non-essential features and the ability
for new features to gain support organically before being incorporated
into your project. The tradeoff is that you need to be careful about API 
compatibility, because other libraries will depend on these features.

For this reason, you may not be able to develop a good extension API in the
early days of a project, but once you are at the point where people are using
your code for things you didn't expect them to, it is a good time to
work in the direction of a stable extension API.

(i.e. the importance of an extension API is proportional to the amount
of active use for purposes other than the author's original intent
that are still "reasonable" within the context of the problem domain,
which is measurable by the number of feature requests / complaints
and the types of things people ask for.

(RDoc examples)
(prawn-templates)
(extension points)

[^1]: The definition of legacy code as code without tests was popularized in 2004 by Michael Feathers, author of the extremely useful [Working Effectively with Legacy Code](http://www.amazon.com/Working-Effectively-Legacy-Michael-Feathers/dp/0131177052) book.

