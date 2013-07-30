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

![Day of week](http://i.imgur.com/QlBajBn.png)

The graph above is a straightforward grouping and averaging by day of week. Since I don't work a normal M-F schedule, it may not be as meaningful for me as it would be for someone else.

The error bars show the standard deviation from the mean for each day. This allows us to see how volitile mood ratings are for a given day -- the tighter the error bars, the more stable the average rating was. Note that this is *not* the same as the min/mix range shown in the previous graph. Min/max here isn't especially useful since every day of the week has the potential to receive a 1 or 9. (although *average* min/max might be useful? -- consider TODO)

Observations (probably separate this out from method discussion above): My worst days (Wed / Sat) are also the most volitile. Those days have historically been "days off" for me, but the lower ratings might not be so easily explained by saying "I like to work more than I like to rest". Those days are also transition points between work and rest, so it may be the context switch that makes me unstable. My best days (Monday and Friday) correspond with when I tend to start something new, and when I tend to "wrap stuff up" for the week, like everyone else. (My weekend work tends to be more about pushing various existing things along rather than starting new stuff or finishing old stuff)


![Frequency](http://i.imgur.com/ZwSNOHTl.png)

Here we break the day into quintets and take a look at the actual distribution of ratings during those time periods.
The exact thing we're showing here is for a given rating number in the time period, what percentage of updates were for that rating number.

The graphs show that as time goes on throughout the day, the number of positive ratings (>= 6) decrease, and the number of of negative ratings (<= 5) increase, up until about 8pm, in which the pattern returns to something quite similar to what is observed in the morning.

The interpretation here is that as willpower is exhausted throughout the day, it becomes easier to have negative experiences. But after dinner and evening chores it's time for relaxation, and that "recharges" the batteries, so to speak. But this story doesn't necessarily match up with what the following graphs show.


![Work days](http://i.imgur.com/a4Bh76u.png)

Here we see averages broken out by hour for days that I've set aside as work days. It shows that my most volitile time periods are from 9am-11am, from 4pm-6pm, and from 8pm-9pm. These mark the well-defined "transition" points of my day... from morning chores to work, from work to evening chores, and from evening chores to "rest".

![Rest days](http://i.imgur.com/oqNGYbJ.png)

Rest days are unfortunately all over the map, with high volitility at most times of the day, especially after 12:00pm and before 9:00pm. There are a number of factors that may come into play here, but one important may be that I have been much less reliable at recording updates during rest periods than I have been during my working time, and so this data may be less reliable and also biased towards extreme events.

However, there is also the factor that "rest days" often have me thinking about my work at inconvenient times and places, and that my own mood tends to mirror that of my son's if we're doing something together. Because the rest days don't have fixed "alone time", it's hard to maintain stability.

There is also a period of several days where we were experiencing major stress in my personal life, and that data could have easily skewed the whole dataset.

It'd be interesting to see whether this smooths out over time or not.

TODO: Think about doing some work to exclude various factors shown above.

--------


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

