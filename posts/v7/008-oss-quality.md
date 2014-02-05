## Developing a quality-centric mindset

The need for high quality standards in software projects is a matter of practicality, not pride. To understand why, it helps to remember that "bad code" is often hard to understand, hard to test, hard to change, and hard to reuse. No matter how useful your software is to the world, poorly written code can get in the way of its future progress.

Once the impact of low quality code reaches a critical mass, the pace of development grinds to a halt, and the temptation is great to either let projects stagnate or to attempt the *big rewrite* with a heavy focus on quality standards. Unfortunately, neither of these outcomes typically end well for a project's existing community of users, because historically speaking the road to maintainer burnout is paved with *big rewrites*.
 
Some will inevitably take these observations as a cautionary tale, and make a solemn promise to themselves and to their community to establish high quality standards for their project from day one; promising to never ship any bad code in their releases, and establishing strict coding guidelines to keep their projects in ship shape at all times. But anyone who has spent enough time down the rabbit hole can tell you that this doesn't really work, either.

Writing high quality code takes time, and you can't be sure that time is well spent until you have a decent understanding of the domain you are working in. In order to quickly build up knowledge about a complex problem space, you need to be able to try out some ideas without allowing quality concerns to slow you down. This approach helps you generate feedback quickly, and what you lose in code quality up front you gain back in insights that can be used to write better code later. The trick is to understand the bargain you are making when doing this, and whether or not the benefits are likely to outweigh the costs. In other words, the path to quality is a balancing act, and it involves making some educated guesses along 
the way.

If you are too strict with your quality standards, you can miss out on healthy experimentation that will improve your project over the long haul, but if you loosen up too much your project will perpetually remain in an experimental state in which none of its code can be trusted. The sweet spot is somewhere between these two extremes, and it pays to actively seek it out rather than just hope to end up there by chance.

An optimal process is one that always keep the quality arrow pointing upwards over the long haul, but isn't so brittle as to prevent necessary experimentation and the occasional mistake from happening. We'll now discuss a few specific tactics that can help you achieve that goal.

### Let external changes drive internal quality improvements

https://github.com/prawnpdf/prawn/issues/570

https://github.com/prawnpdf/prawn/pull/579 (complicated)

In an early-stage project, there will be areas of code that are bad because you aren’t yet familiar with the problem domain you are working in. In a more mature project, there will still be “new areas” that are experimental, and you will also have a fair amount of code that has decayed either due to technical drift, shifts in priorities, or just general negligence.

Having some technical debt is only natural on most software projects, and there’s no getting around it unless you have an extremely disciplined team with endless resources and no external pressures. Open-source projects tend to have a much more diverse environment than that, so it is unrealistic to assume that “ideal software practices” will apply to your projects as an open-source maintainer.

The key is to manage the chaos and use your time well. Assume that there will be rough patches, and seek to isolate them when you can, and minimize their impact when you cannot.
An easy way to do that is to simply focus on improving quality wherever you are actively working in the code.

For any non-trivial bug fix or new feature, you will need to work with various components in your system, some that are in decent shape, and others that have fallen into disrepair. If you stop to refactor entire functions and classes every time you encounter bad code along your path, what could be an incremental change will turn into a much bigger project. The work may be worthwhile in its own right, but it may take away from everything else you could be doing to improve 
the project.

Take a moment now to consider the following diagram. In it, the rectangle represents your entire codebase. The light blue regions represent code that is easy to work with, and the pink regions represent code that is difficult to work with. The arrows represent the areas of your project you will need to work on in order to build a feature or fix.

Rather than completely fixing any problematic areas of code we find along the path, we instead refactor just in the immediate area around the work we are doing (represented in dark blue below). In doing so, the problematic areas of the code will get broken up a bit, until eventually it becomes easier to change your software without encountering bad code that slows you down.

![](http://i.imgur.com/PHwPkyD.png)

In practice, this might mean doing simple things like extracting helper methods, or building method objects rather than rewriting and updating the tests for an entire method. Doing this splits one big messy chunk of code into a small section of good code and a slightly smaller section of bad code. As the bad sections become smaller and smaller, it becomes more and more realistic to eliminate them entirely, without spending a large amount of time purely dedicated to 
refactoring and cleanup.

### Increase test coverage and clarity as your project matures

Example: https://github.com/rubygems/rubygems/pull/781
(Maybe add more complicated ones, too? -- especially ones where the test isn't
good enough)

Ensuring 100% test coverage at all times is a noble goal, but is not always practical. Even when full test coverage exists, it is often only a sign that “all the code gets run by the test suite”, and it’s not an indicator of how clear or well-defined the tests themselves are. In the experimental phases of a project, sometimes writing only very loose tests can be a good idea, and in some cases, it’s fine to have no tests at all.

However, test coverage becomes more important as a project matures, because tests set the expectations about how the features of a project are meant to behave. As people write code that depends on features from a library, or as the library itself depends on its own features internally, poorly specified features can easily become broken without the build breaking along with it. These problems will probably not be noticed as soon as the change is introduced, but instead will surface later when someone encounters the problem indirectly.

The effect of inadequate testing is that much of the behavior of a project remains either undefined or held in the head of a handful of people who understand the design ideas behind 
the project. These problems tend to compound over time, and a point is eventually reached where no meaningful changes can be made to a project without breaking something else 
in the process.

* When reviewing a pull request, check to make sure that new behavior has tests, and that they are written precisely enough that you will understand them several months from now. If anything is unclear, discuss it with the submitter and then add additional specs to cover the assumptions.

* Also look to see whether the code depends on existing features that either do not have tests, or have tests that are underspecified. In most cases, adding additional test coverage one layer out will help prevent you from seeing a higher level feature and not understanding why when a low-level feature changes in some subtle way.

* Be extra wary of changes to existing features. Even if the change is covered by tests, the base behavior may not be adequately covered.

* If bugs are encountered while working on integrating a new change, add tests for those as well.

* If the change is a bugfix itself, make sure that it captures the bug at the actual level it is happening at, and not just at the surface level. Usually it makes sense to add a test at two levels: the level it was discovered at, and at the source of the problem. But if you choose only one, pick the source level.

* For a bug fix, create reproducing examples by stripping away layers until you can no longer reproduce an incorrect behavior. Then clarify the correct behavior at that level.

* For a feature, make sure that use cases are clearly defined, if not in the tests then at least in the pull request discussion or an example file. These will help you interpret the intention behind the tests, rather than just the assertions. Augment the specs with any clarifications as needed.

* Even if a pull requests has tests of its own and the full suite passes, is it built on top of code that is poorly tested? If so, there may be built in assumptions that are invalid. Helps to at least push the wall back one level out.

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


