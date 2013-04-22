**Problem: Code for data munging projects can easily become brittle.**

Whenever you work on a project that involves a significant amount of data
munging, you can expect to get some mud on your boots. Even if the individual
aggregation and transformation steps are simple, complexity arises from
messy process of assembling a useful data processing pipeline. With each
new change in requirements, this problem can easily be compounded in
brittle systems that have not been designed with malleability in mind.

As an example, imagine that you are implementing a tool that
delivers auto-generated email newsletters by aggregating and 
filtering links from Reddit. The following workflow provides
a rough outline of what that sort of program would need to
do in order to complete its task:

1. Download a blob of JSON via Reddit's API containing raw link data from a
particular subreddit.

2. Convert that data into an intermediate format that can be processed by the
rest of the program.

3. Apply filters to ignore links that have already been included in a previous
newsletter, or fall below a minimum score threshold. 

4. Convert the curated list of links into a human readable format.

5. Send out the formatted list via email using GMail's SMTP servers.

Some will look at this set of steps and see a standalone script as the right
tool for the job: the individual steps are simple, and the time investment is
small enough that you could throw the entire script away and start again if you
end up facing significant changes in requirements.

Others will see this as a perfect opportunity to put together an elegant domain
model that supports a classic object-oriented design style. By encapsulating all
of these ideas in generalized abstractions, endless changes would be possible in
the future, thus justifying the upfront design cost.

Both of these perspectives have merit, but it would be unwise to set up a
false dichotomy between formal design and skipping the design process entirely. 
Interesting solutions to this problem also exist in the space between these two extremes,
and so we'll take a look at one of them now.

**Solution: Reduce the cost of rework by organizing your codebase into
replaceable single-purpose components.**

\newpage

```ruby
basedir = File.dirname(__FILE__)

history   = Spyglass::Data::History.new("#{basedir}/history.store")
min_score = 20

selected_links = Spyglass::LinkFetcher::Reddit.("ruby").select do |r| 
  r.score >= min_score && history.new?(r.url) 
end

history.update(selected_links)

message = Spyglass::Formatter::PlainText.
            (links: selected_links, template: "#{basedir}/message.erb")

Spyglass::Messenger::DeliverGmail.
  (subject: "Links for you!!!!!!", message: message)
```

... Objects for data, functions for action.
Not pure functions (can have side effects)

.. Context independence! Each component is understandable in isolation from the
rest of the system


What we're really looking for is a design that gets some of the
organizational benefits of object-oriented programming while preserving a bit of
the quick-and-dirty nature of ad hoc scripting.

This is not the same as building general purpose libraries / frameworks
(abstraction is not important, nor is careful interface design!)

(In other words, apply the single responsiblity principle aggressively)
yadda.. yadda... functional programming something something.

Your objects become a toolchest of sorts to assist in the tasks carried out by
your scripts.

You don't always start this way (in fact you often don't), you may get here via
the process described in 6.8
