One human quirk that fascinates me is the huge disparity between our moment-to-moment experiences and our perception  of past events. This is something that I've read about a lot in pop-psych books, and also is one of the main reasons that I practice insight meditation. However, it wasn't until I read Daniel Kahneman's book "Thinking, Fast and Slow" that I realized just how strongly separated our *experiencing self* is from our *remembering self*. 

In both Kahneman's book and [his talk at TED 2010](http://www.ted.com/talks/daniel_kahneman_the_riddle_of_experience_vs_memory.html), he uses a striking example comparing two colonoscopy patients who recorded their pain levels periodically throughout their procedure. From the data he shows, the first patient has a much shorter procedure and reports much less pain overall during the procedure than the second patient. However, when asked later about how painful the procedure was, the first patient remembered it to be much more unpleasant than the second patient did. How can that be?

As it turns out, how an event ends has a lot to do with how we will perceive the overall experience when we recall it down the line. In the colonoscopy example, the first patient reported a high pain spike immediately before the end of their procedure, where the second patient had pain that was gradually reduced before the procedure ended. This is the explanation Kahneman offers as to why the first patient remembered their colonoscopy to be far worse of an experience than the second patient remembered it to be. 

This disparity between experience and memory isn't just a one-off observation -- it's a robust finding, and it is has been repeated in many different contexts. The main lesson to learn from it is that we cannot trust our remembering mind to give a faithful account of the things we experience day-to-day. The unfortunate cost that comes along with this reality is that we're not as good about making judgements about our own well being as we could be if we did not have this cognitive limitation.

I thought about this idea for a long time, particularly as it related to my day-to-day happiness. Like most software developers (and probably *all* writers), my work has a lot of highs and lows to it -- so my gut feeling was that my days could be neatly divided into good days and bad days. But because Kahneman had taught me that my intuitions couldn't be trusted, I eventually set out to turn this psychological problem into an engineering problem by recording and analyzing my own mood ratings over time.

## Designing an informal experiment

I wanted my mood study to be rigorous enough to be meaningful on a personal level, but I had no intentions of conducting a tightly controlled scientific study. What I really wanted was to build a simple breadcrumb trail of mood ratings so that I didn't need to rely on memory alone to gauge how my overall sense of well-being fluctuated over time.

After thinking through various data collection strategies, I eventually settled on SMS messages as my delivery mechanism. The main reason for going this route was that I needed a polling mechanism that could follow me everywhere, but one that wouldn't badly disrupt whatever I was currently doing. Because I use a terrible phone that pretty much can only be used for phone calls and texting, this approach made it possible for me to regularly update my mood rating without getting sucked into all the things that would distract me on a computer.

The data I was interested in tracking was a simple number rating that described my current mood whenever I sent an update. Although the ratings themselves were purely subjective, they roughly aligned to the following scale:

* Very Happy (9): No desire to change anything about my current experience.
* Happy (7-8):  Pleased by the current experience, but may still be slightly tired, distracted, or anxious.
* Neutral (5-6): Not bothered by my current experience, but not necessarily enjoying it.
* Unhappy (3-4): My negative feelings are getting in the way of me doing what I want to do.
* Very Unhappy (1-2): Unable to do what I want to do because I am overwhelmed with negative feelings.

Originally I had intended to simply collect this data over the course of several weeks without any specific questions in mind. However, Jia convinced me that having at least a general sense of what questions I was interested in would help me organize the study better, so I started to think about what I might be able to observe from this seemingly trivial dataset.

After a short brainstorming session, we settled on the following general questions:

* Are there noticeable differences in my mood between rest days and work days?
* Does day of the week and time of day have any effect on my mood?
* How stable is my mood in general? In other words, how much variance is there over a given time period?
* Are there any patterns in the high and low points that I experience each day? How far apart are the two?

These questions helped me ensure that the data I intended to collect was sufficient. Once we confirmed that was the case, we were ready to start writing some code!

## Building the data collection and reporting tools

Data Collection:

1. A rake task is run every 10 minutes, and has a one in six chance of sending an update notification.
2. A sinatra application listens for calls from that rake task, and then delivers a SMS message via Twilio
3. I respond to that message with my mood rating, which is then passed along via a webhook back to that same sinatra application.
4. A timestamp and the rating is then stored in the database.

Reporting:

1. The same sinatra application that handles the SMS stuff also provides a CSV data export. This includes the raw data, along with some basic derived fields.
2. This CSV data is used by a menagerie of R scripts to produce graphs and statistical calculations.
3. A Prawn-based script converts the outputs from the R scripts into a single PDF report.

(all of this shit is tied together through rake)

Coupling is fairly low across the whole toolchain:

* The scheduler only talks to my sinatra application, so it doesn't know anything about our service dependencies
* The reporting code relies only on a downloaded CSV, so it doesn't need to directly interact with a database, and can be run against a local file without an internet connection.
* The PDF generation code doesn't know anything about the reporting logic, it is solely responsible for 
displaying the images and nothing else.

## Analyzing the results

## Interpreting my observations

## Conclusion

*If the purpose of classical data analysis is to find convincing answers to well-defined questions, then the role of exploratory data analysis is to help us find the right questions to ask. Although these two approaches are ultimately two sides of the same coin, they represent two very different ways of thinking about a problem.*

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

