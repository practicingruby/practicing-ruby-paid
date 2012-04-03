Over the last several years, Ruby programmers have gained a reputation of being
*test obsessed* -- a designation that many of our community members consider to
be a badge of honor. While I share their enthusiasm to some extent, I can't help but notice
how dangerous it is to treat any single methodology as if it were a panacea.

Our unchecked passion about [test-driven
development](http://en.wikipedia.org/wiki/Test-driven_development) (TDD) has paved the way for deeply
dogmatic thinking to become our cultural norm. As a result, many vocal members
of our community have oversold the benefits of test-driven development 
while downplaying or outright ignoring some of its costs. While I don't doubt
the good intentions of those who have advocated TDD in this
way, I feel strongly that this tendency to play fast and loose with very complex
ideas ends up generating more heat than light.

To truly evaluate the impact that TDD can have on our work, we need to go 
beyond the anecdotes of our community leaders and seek answers to 
two important questions:

> 1) What evidence-based arguments are there for using TDD? 

> 2) How can we evaluate the costs and benefits of TDD in our own work?

In this article, I will address both of these questions and share with you my
plans to investigate the true costs and benefits of TDD in a more rigorous and
introspective way than I have done in the past. My hope is that by considering a
broad spectrum of concerns with a fair amount of precision, I will be able to
share relevant experiences that may help you challenge and test your own 
assumptions about test-driven development.

### What evidence-based arguments are there for using TDD? 

Before publishing this article, I conducted a survey that collected thoughts
from Practicing Ruby readers about the costs and benefits of test-driven
development they have personally experienced. Over 50 individuals responded, and
as you might expect there was a good deal of diversity in replies. However, the
following common assumptions about TDD stood out:

```diff
+ Increased confidence in developers working on test-driven codebases
+ Increased protection from defects, especially regressions
+ Better code quality (in particular, less coupling and higher cohesion)
+ Tests as a replacement/supplement to other forms of documentation
+ Improved maintainability and changeability of codebases
+ Ability to refactor without fear of breaking things
+ Ability of tests to act as a "living specification" of expected behavior
+ Earlier detection of misunderstandings/ambiguities in requirements
+ Smaller production codebases with more simple designs
+ Easier detection of flaws in the interactions between objects
+ Reduced need for manual testing
+ Faster feedback loop for discovering whether an implementation is correct
- Slower per-feature development work because tests take a lot of time to write
- Steep learning curve due to so many different testing tools / methodologies
- Increased cost of test maintenance as projects get larger
- Some time wasted on fixing "brittle tests"
- Effectiveness is highly dependent on experience/disciple of dev team
- Difficulty figuring out where to get started on new projects
- Reduced ability to quickly produce quick and dirty prototypes
- Difficulty in evaluating how much time TDD costs vs. how much it saves
- Reduced productivity due to slow test runs
- High setup costs
```

Before conducting this survey, I compiled my [own list of
assumptions](https://gist.github.com/2277788) about test-driven 
development, and I was initially relieved to see that there was a high degree of
overlap between my intuition and the experiences that Practicing Ruby 
readers had reported on. However, my hopes of finding some solid ground to stand
on were shattered when I realized that virtually all of these claims did not have
any conclusive empirical evidence to support them.

Searching the web for answers, I stumbled across a great [three-part
article](http://scrumology.com/the-benefits-of-tdd-are-neither-clear-nor-are-they-immediately-apparent/)
 called "The benefits of TDD are neither clear nor are they immediately
apparent", which presents a fairly convincing argument that we don't know as
much about the effect of TDD on our craft as we think we do. The whole article is
worth reading, but this paragraph in [part
3](http://scrumology.com/the-benefits-of-tdd-why-tdd-part-3/) really grabbed my
attention:

> Eighteen months ago, I would have said that TDD was a slam dunk. Now that I’ve taken the time to look at the papers more closely … and actually read more than just the introduction and conclusion … I would say that the only honest conclusion is that TDD results in more tests and by implication, fewer defects. Any other conclusions such as better design, better APIs, simpler design, lower complexity, increased productivity, more maintainable code etc., are simply not supported.

Throughout the article, the author emphasizes that he belives in the value of
TDD and seems to blame the inconsistent quality and rigor of the studies for a
big part of why their results do not mirror the expectations of practicioners.
He even offers some standards for what he believes would make for more reliable
studies on TDD, and most of his points seem reasonable to me:

> My off-the-top-of-my-head list of criteria for such a study, includes (a) a multi year study with a minimum of 3 years consecutive years (b) a study of several teams (c) team sizes must be 7 (+/-2) team members and have (d) at least 4 full time developers. Finally, (e) it needs to be a study of a product in production, as opposed to a study based on student exercises. Given such as study it would be difficult to argue their conclusions, whatever they be.

His points (c) and (d) about team size seem subject to debate, but it seems fair
to say that studies should at least consider many different team sizes as
opposed to focusing on individual developers exclusively. All other points he
makes seem essential to ensuring that results remain tied to reality, but he
goes on to conclude that his requirements are so complicated and costly to 
implement that it could explain why all existing studies fall short of this gold
standard.

Intrigued by this article, I went on to look into whether there were other, more
authoritative sources of information about the overall findings of research on
test-driven development. As luck would have it, the O'Reilly book on
evidence-based software engineering ([Making
Software](http://www.amazon.com/Making-Software-Really-Works-Believe/dp/0596808321)) had a chapter on this
topic called "How effective is test-driven development?" which followed a
similar story arc.

In this chapter, five researchers present the result of their systematic review of 
quantitative studies on test driven development. After anaylzing what published 
literature says about internal quality, external quality, productivity, 
and correctness testing, the researchers found some evidence that both 
correctness  testing and external quality are improved through TDD. However, 
upon limiting the scope to well-defined studies only, the positive effect 
on external quality disappears, and even the effect on correctness 
testing weakens significantly. In other words, their conclusion matched the
conclusions of the previously mentioned article: <u>*there is simply not a whole lot of
science supporting our feverish advocacy of TDD and its benefits.*</u>

While the lack of rigorous and conclusive evidence is disconcerting, it is not 
necessarily a sign that our perception of the costs and benefits of 
TDD are invalid. Instead, we should treat these findings as an invitation to
slow down and look at our own decision making process in a more careful and
introspective way. 

### How can we evaluate the costs and benefits of TDD in our own work?

List out questions I am interested in

### Plans for deeper investigation

### Predictions about what will be discovered

### Limitations of this method of study

### Some things you can do to help out 
