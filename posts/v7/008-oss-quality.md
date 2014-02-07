The need for high quality standards in open-source projects is a matter of practicality, not pride. To understand why, it helps to remember that "bad code" is often hard to understand, hard to test, hard to change, and hard to reuse. No matter how useful your software is to the world, poorly written code can get in the way of its future progress.

Once the impact of low quality code reaches a critical mass, the pace of development grinds to a halt, and the temptation is great to either let projects stagnate or to attempt the *big rewrite* with a heavy focus on quality standards. Unfortunately, neither of these outcomes typically end well for a project's existing community of users, because historically speaking the road to maintainer burnout is paved with *big rewrites*.
 
Some will inevitably take these observations as a cautionary tale, and make a solemn promise to themselves and to their community to establish high quality standards for their project from day one; promising to never ship any bad code in their releases, and establishing strict coding guidelines to keep their projects in ship shape at all times. But anyone who has spent enough time down the rabbit hole can tell you that this doesn't really work, either.

Writing high quality code takes time, and you can't be sure that time is well spent until you have a decent understanding of the domain you are working in. In order to quickly build up knowledge about a complex problem space, you need to be able to try out some ideas without allowing quality concerns to slow you down. This approach helps you generate feedback quickly, and what you lose in code quality up front you gain back in insights that can be used to write better code later. The trick is to understand the bargain you are making when doing this, and whether or not the benefits are likely to outweigh the costs. 

The path to quality is a balancing act, and it involves making some educated guesses along the way. If you are too strict with your quality standards, you can miss out on the healthy experimentation you need to improve your project over the long haul. But if allow things to get too loose, and project will perpetually remain in a state of flux where none of its code can be trusted. The sweet spot is somewhere between these two extremes, and it pays to actively seek it out rather than just hope to end up there by chance.

An optimal process is one that always keep the quality arrow pointing upwards over the long haul, but isn't so brittle as to prevent necessary experimentation and the occasional mistake from happening. We'll now discuss a few specific tactics that can help you achieve that goal.


### Let external changes drive internal quality improvements

You don't need an extremely disciplined team with endless resources to successfully manage an open source project, but you do need to develop a pragmatic way of looking at things. There will always be rough patches in your codebase, and it pays to focus only on the ones that are having the most impact on the project as a whole. Attempting to deal with each and every pain point you encounter will eat away at energy that would be better spent moving your project forward, warts and all. Clean code does makes a difference, but your ability to use your time wisely is far more important.

Most non-trivial bug fixes and improvements to your project will require you to understand and interact with several of its components, and its likely that at least some of them will be in a state of disrepair. This is a common scenario for any software project, but open source projects complicate matters because they are often developed by way of one-off patches from near-strangers that solve one particular problem and then disappear into the ether. With everything always shifting under foot, it is unrealistic to expect that any large scale cleanup efforts will be particularly efficient, if they are even effective at all.

A better way to keep a project stable as it grows is to simply focus on improving quality wherever people are actively working in the codebase. This is something that can be done a little at a time, and it can be done without taking too much effort away from producing valuable user-facing changes. Taking this approach makes it so that you don't need to explicitly schedule time to spend on a "big cleanup" -- you just need to leave the code better off than you found it whenever you set out to do some work. 

By repeating this process over and over, the problematic areas of your project's codebase will gradually break up into smaller and smaller chunks, until eventually it becomes easy to make many kinds of meaningful change without bad code getting in the way.  Even though incremental quality improvements won't make you feel like a hero in the way that a highly focused cleanup effort might, it is a much more sustainable approach over the long haul for two reasons: it requires a much smaller initial investment, and it allows you to benefit from the knowledge gained over time about what is actually important to work on in your project.

**Examples of incremental quality improvements**

https://github.com/prawnpdf/prawn/issues/570

https://github.com/prawnpdf/prawn/pull/579 (complicated)

(legacy article for a MUCH longer example)

### Treat all code without adequate testing as legacy code

Historically, we've defined legacy code as code that was written long before our time, without any consideration for our current needs. However, any code without adequate test coverage can also be considered legacy code[^1], because it often has many of the same characteristics that make outdated systems difficult to work with.

The lifecycle of an open source project is effectively infinite and the scope of its problem domain is often left open-ended, and that means that most maintainers see their fair share of both antiquated and poorly tested code. Knowing how to work skillfully with legacy code in a project and can go a long way towards raising overall quality and maintainability.

The most direct way to guard against the negative impacts of legacy code is to keep growing and maintaining your project's automated test suite so that it constantly reflects your current understanding of the problem domain you are 
working in, along with any formal assumptions you have about how your code is meant to be used. These goals cannot be met by simply having good code coverage and keeping the build
green in CI, although that may be a good place to start if you aren't already at that level with your testing setup. 

The important thing to note is that even when full test coverage exists, it is often only a sign that “all the code gets run by the test suite”, and it’s not an indicator of how clear or well-defined the tests themselves are. In the experimental phases of a project, sometimes writing only very loose tests can be a good idea. But if you do not go back to refine these tests later when you want to stabilize your codebase, underspecification tends to lead to undefined behaviors that turn into bugs as soon as an incorrect assumption is made about them.

Rigorous testing becomes increasingly important as a project matures, because by then more people and projects will expect your code to be stable. With the right kind of attention to detail, your test suite can be a very powerful tool for setting expectations about how the features of your project are meant to behave, and you will also catch more accidental behavior changes before they leak out into released software.

The better your test suite is, the safer it will be for you to accept the help of strangers who may not have any plans to stick around for the long haul. It will also make contributors happy, because they will be able to experiment with making changes to your codebase without fear of accidentally breaking some unrelated feature.

Because you can't assume that everyone working on your project will practice rigorous TDD and constantly check their assumptions about the intent behind each minor feature's implementation, most of the verification and further cultivation of your test suite will happen at code review time. Here are some guidelines that can be helpful when considering new change requests, no matter what state your project is currently in:

* When reviewing a pull request, check to make sure that new behavior has tests, and that they are written precisely enough that you will understand them several months from now. If anything is unclear, discuss it with the submitter and then add additional specs to cover the assumptions.

* Also look to see whether the code depends on existing features that either do not have tests, or have tests that are underspecified. In most cases, adding additional test coverage one layer out will help prevent you from seeing a higher level feature and not understanding why when a low-level feature changes in some subtle way.

* Be extra wary of changes to existing features. Even if the change is covered by tests, the base behavior may not be adequately covered.

* If bugs are encountered while working on integrating a new change, add tests for those as well.

* If the change is a bugfix itself, make sure that it captures the bug at the actual level it is happening at, and not just at the surface level. Usually it makes sense to add a test at two levels: the level it was discovered at, and at the source of the problem. But if you choose only one, pick the source level.

* For a bug fix, create reproducing examples by stripping away layers until you can no longer reproduce an incorrect behavior. Then clarify the correct behavior at that level.

* For a feature, make sure that use cases are clearly defined, if not in the tests then at least in the pull request discussion or an example file. These will help you interpret the intention behind the tests, rather than just the assertions. Augment the specs with any clarifications as needed.

* Even if a pull requests has tests of its own and the full suite passes, is it built on top of code that is poorly tested? If so, there may be built in assumptions that are invalid. Helps to at least push the wall back one level out.

* Try to educate contributors about your process and how to make future pull requests go more smoothly, but don't expect them to do your maintenance work for you.

**Examples from our projects**

(Maybe add more complicated ones, too? -- especially ones where the test isn't
good enough)

https://github.com/rubygems/rubygems/pull/781

### Make good use of extension points to limit your project's scope

Although clients are likely to change their mind and product companies are
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

