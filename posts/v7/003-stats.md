
# A humble introduction to exploratory data analysis

Many people never develop strong data analysis skills, mostly due to a lack of formal training in statistical modeling. For someone who has spent a good chunk of their career building web applications, the idea of going back and learning a lot of abstract mathematical principles might seem a bit intimidating. This is only natural, particularly because there is always so much to learn, and so little time to do it in.

But because we now live in a deeply data-driven world, programmers will need to develop a stronger understanding of how data analysis techniques can be used to transform raw data into useful information. Although we may end up leaving the heavy statistical modeling to specialists and domain experts, we can and should learn how to do some basic data exploration tasks on our own.

In this article, I will walk you through a small data analysis project that I put together to practice these skills. Along the way, I'll share some helpful tools and techniques that you can make use of in your own projects.

## The project: Study my mood over time

*If the purpose of classical data analysis is to find convincing answers to well-defined questions, then the role of exploratory data analysis is to help us find the right questions to ask. Although these two approaches are ultimately two sides of the same coin, they represent two very different ways of thinking about a problem.*

In other words, these are metrics rather than predictive measures, equivalent to code smells!

## The setup

## Results

## Interpretation

## Conclusion



---

## Update with latest stats + report before shipping

* 9: Fully content. no desire to change anything
* 7-8: Happy. but possibly slightly tired or distracted (etc)
* 5-6: Neutral. Doing something worthwhile, but not necessarily enjoying it because I'm either preoccupied about something else or the task itself is mundane, or both!
* 3-4: Upset. My negative feelings are getting in the way of me doing what I want to do.
* 1-2: Distressed. Unable to do what I want to do because I am overwhelmed with negative feelings.

Things I was curious about:

* Difference between work days and rest days
* How much I'm affected by especially good and bad moods
* Differences between days of week and times of day
* How volatile my mood is in various contexts
* What range does my mood span day to day? How high is the "average high", how low is the "average" low?

How I did it:

* Used a scheduled job which ran every ten minutes and had a one in six chance of sending me text messages asking for a mood rating.
* Stored responses (1-9) in the database, along with a timestamp
* Added some derived data from the raw data and made it available for download as a CSV
* Wrote a menagerie of R scripts to process this data and run computations related to the questions above.
* Used a rake file and some prawn code to make it easy to generate a PDF with all the results by running a single command.

schema:

```ruby
DB.create_table(:mood_logs) do
  primary_key :id
  String  :message
  Integer :recorded_at
end
```

inputs:

```
1371164911	5	1	19	Thu	4
1371167535	3	1	19	Thu	4
1371169234	6	1	20	Thu	4
1371171527	5	1	20	Thu	4
1371179119	9	1	23	Thu	4
1371215462	7	2	9	Fri	5
1371227121	7	2	12	Fri	5
1371227312	8	2	12	Fri	5
1371233322	4	2	14	Fri	5
1371234537	5	2	14	Fri	5
1371235126	5	2	14	Fri	5
1371235739	5	2	14	Fri	5
```

outputs:
http://notes.practicingruby.com/mood-study-draft-2.pdf

----

![Summary](http://i.imgur.com/aOVm2Sc.png)

The summary graph above shows a weighted average of the mood updates over the entire study time period, considering a moving window of 20 data points at a time, and applying exponential smoothing. It gives a feel for the general ups and downs throughout the study, without being too noisy:

If we plotted the individual points, we'd see nothing but noise (there are hundreds of them), and if we plotted daily averages, you wouldn't see much difference across the whole study. In particular, you wouldn't be able to tell the difference between (1,1,1,9,9,9) and (5,5,5,5,5,5).

It's important to remember that "average mood" still doesn't mean that the number shown is closest to what was actually experienced at a given point in time. But as the average mood number increases you can infer that experienced mood is generally improving over time, and vice-versa.

The global average and standard deviation mostly give us a similar measure: If we generated this graph every 60 days, it'd tell us a lot to see a significant difference in either of these numbers. Change in global average tells us of grand-scale changes to overall mood, and change in standard deviation tells us how "volatile" the mood ratings have been. A tight standard deviation implies strong mood regulation, a wide distribution implies weak mood regulation.


![Min Max](http://i.imgur.com/p65gNPp.png)

In a purely statistical sense, the highest and lowest values reported for each day might be considered outliers that could be stripped out or ignored if they aren't close enough to the mean. However, the nature of this study makes it so that those extreme values are of interest: Even if the "average" mood for two days were both around 7, a day where a single mood rating of 1 was reported will certainly be different than a day where the lowest rating was a 5!

So to fill in this missing information, the graph above shows the extreme high and low for each day in the study. From it, we can see that there was only one day where I didn't report at least a single rating of 7 or higher, and that most days my high point was either an 8 or 9. We can also see that although the majority of days had a lower limit of 5 or higher, about 20% of days had a rating of 4 or lower.

If you view the space betweeen the two graphs as a "cave", the ideal situation for maximizing mood stability would be for the both the "floor" and "ceiling" to be as high as possible.

Unfortunately, this graph is much uglier than we wish it was, suggestions are welcome!

TODO: Try to color green above the curve, and coral below the curve, to make a sort of "cave view". Consider going back to rectangles for this.

NOTE: Mention lowest observed is not necessarily lowest experienced

![Day of week](http://i.imgur.com/QlBajBn.png)

The graph above is a straightforward grouping and averaging by day of week. Since I don't work a normal M-F schedule, it may not be as meaningful for me as it would be for someone else.

The error bars show the standard deviation from the mean for each day. This allows us to see how volitile mood ratings are for a given day -- the tighter the error bars, the more stable the average rating was. Note that this is *not* the same as the min/mix range shown in the previous graph. Min/max here isn't especially useful since every day of the week has the potential to receive a 1 or 9.

Observations (probably separate this out from method discussion above): My worst days (Wed / Sat) are also the most volitile. Those days have historically been "days off" for me, but the lower ratings might not be so easily explained by saying "I like to work more than I like to rest". Those days are also transition points between work and rest, so it may be the context switch that makes me unstable. My best days (Monday and Friday) correspond with when I tend to start something new, and when I tend to "wrap stuff up" for the week, like everyone else. (My weekend work tends to be more about pushing various existing things along rather than starting new stuff or finishing old stuff)

TODO: One way ANOVA + Post-hoc test on means each day -- expect to see wed and sat to stand out
      Variance test on stdev -- expect wed to stand out as more volatile


![Frequency](http://i.imgur.com/ZwSNOHTl.png)

Here we break the day into quintets and take a look at the actual distribution of ratings during those time periods.
The exact thing we're showing here is for a given rating number in the time period, what percentage of updates were for that rating number.

The graphs show that as time goes on throughout the day, the number of positive ratings (>= 6) decrease, and the number of of negative ratings (<= 5) increase, up until about 8pm, in which the pattern returns to something quite similar to what is observed in the morning.

The interpretation here is that as willpower is exhausted throughout the day, it becomes easier to have negative experiences. But after dinner and evening chores it's time for relaxation, and that "recharges" the batteries, so to speak. But this story doesn't necessarily match up with what the following graphs show.

TODO: Check frequency of five or lower (total percentage), see if there is a linear trend of decreasing from morning to 8pm, then increasing at the end.  


![Work days](http://i.imgur.com/a4Bh76u.png)

Here we see averages broken out by hour for days that I've set aside as work days. It shows that my most volitile time periods are from 9am-11am, from 4pm-6pm, and from 8pm-9pm. These mark the well-defined "transition" points of my day... from morning chores to work, from work to evening chores, and from evening chores to "rest".

-- consider showing transition points in different color. No stats are needed, just use a descriptive statement about the graph

![Rest days](http://i.imgur.com/oqNGYbJ.png)

Rest days are unfortunately all over the map, with high volitility at most times of the day, especially after 12:00pm and before 9:00pm. There are a number of factors that may come into play here, but one important may be that I have been much less reliable at recording updates during rest periods than I have been during my working time, and so this data may be less reliable and also biased towards extreme events.

However, there is also the factor that "rest days" often have me thinking about my work at inconvenient times and places, and that my own mood tends to mirror that of my son's if we're doing something together. Because the rest days don't have fixed "alone time", it's hard to maintain stability.

There is also a period of several days where we were experiencing major stress in my personal life, and that data could have easily skewed the whole dataset.

It'd be interesting to see whether this smooths out over time or not.

--TODO: Add an afterward with few days of really bad outliers omitted.

----




--------

Mention GGPlot2

1. individual days, relationship between mood and time of the day
patterns.days break into 3 hours 8am to 11pm, 15 hours.
8-11, 11-2, 2-5, 5-8, 8-11.

2. work day or rest day, mood difference

3. the drag effect, if there is a number stands out background, find outlier 
(<3 or >8), take n (maybe 10) data points around it, average different from 
global average?

Consider doing a day of the week histogram.

---

Discuss that the data exploration method is scientific but the measured data is
not. If we switched to vital signs or spit test for hormone, could use
similar tests and get objective results (downside: narrow the scope,
because "mood" is a subjective concept).

---

Discuss what processing is done in Ruby vs. R
(Ruby: General data munging (time conversions, etc), R computational munging)

---

Discuss significance (t-test) on time-of-day question

5-8pm period seems to stand out against the background significantly
8am-11am does not (even though it's visually observable)

discuss why

(consider re-running test with density(percentage) instead of absolute values)

---

Discuss decisions made while working on figures:

- Plot density rather than absolute frequency to get everything on the same y
  scale (and to account for non-equal distribution of check-ins)

