# TAG AND REPLACE ALL LINKS BEFORE SHIPPING!
# Update with latest stats, images, + report before shipping (important for this to be consistent!)
# Send to Twilio
# Change URL before shipping

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

In order to run this study, I needed to build two small toolchains: one for data collection, and one for reporting.

The job of the data collection toolchain was primarily to deal with sending and receiving text messages at randomized intervals, dumping the responses into database records similar to what you see below:

```
[{:id=>485, :message=>"8", :recorded_at=>1375470054},
 {:id=>484, :message=>"8", :recorded_at=>1375465032},
 {:id=>483, :message=>"8", :recorded_at=>1375457397},
 {:id=>482, :message=>"9", :recorded_at=>1375450750},
 {:id=>481, :message=>"8", :recorded_at=>1375411347}, ...]
```

To support this workflow, I relied almost entirely on external services, including Twilio and Heroku. As a result, the whole data collection toolchain I built consisted of around 80 lines of code, roughly evenly distributed between two simple [rake tasks](https://github.com/sandal/dwbh/blob/master/Rakefile) and a small Sinatra-based [web service](https://github.com/sandal/dwbh/blob/master/dwbh.rb). Here's the basic storyline that describes what these two little programs are used for:

1. Every ten minutes between 8:00am and 11:00pm each day, a randomizer gets run that has a one in six chance of triggering a mood update reminder.

2. Whenever the randomizer decides to send a reminder, it does so by hitting the `/send-reminder` route on my web service, which then uses Twilio to deliver a SMS message to my phone.

3. I respond to those messages with my current mood rating. This causes Twilio to fire a webhook that hits the `/record-mood` route on my web service with the message data as GET parameters. The data gets massaged slightly, then it is stored in a database for later processing.

4. Some time later, the reporting toolchain will hit the `/mood-logs.csv` route to download a CSV dump of the whole dataset, which includes the raw data shown above along with a few other computed fields that make reporting easier.

After a bit of hollywood magic involving a menagerie of R scripts, some more rake tasks, and a bit of Prawn-based PDF generation code, the reporting toolchain ends up spitting out a [two-page PDF report](http://notes.practicingruby.com/mood-study-draft-2.pdf) that looks like what you see below:

[![](http://i.imgur.com/pcXuVWE.png?1)](http://notes.practicingruby.com/mood-study-draft-2.pdf)

We'll be discussing some of the details about how the various graphs get generated and the challenges involved in implementing them later on in this article, but if you want to get a sense of what the Ruby glue code looks in the reporting toolchain, I'd recommend starting with its [Rakefile](https://github.com/elm-city-craftworks/practicing-ruby-examples/blob/master/v7/003/Rakefile). The basic idea is that with these tasks set up, I'm able to type `rake generate-report` in my console and cause the following chain of events to happen:

1. The latest mood data will be downloaded from my web service in CSV format

2. All of my R-based graphing scripts will be run, outputting a bunch of image files

3. A PDF will be generated that nicely lays out these image files

4. The CSV data and image files will then be deleted, because they're no longer needed.

Between this reporting code and the data aggregation toolchain, I ended up with a system that has been very easy to work with for the many weeks that I have been running this study. The whole user experience boils down to entering single digit values into my phone when I'm prompted to do so, and then typing a single command to generate my reports whenever I want to take a look at them.

At a first glance, the way this system is implemented may look a bit like its hung together with shoestrings and glue, but the very loose coupling between its components has made it easy to both work on individual pieces in isolation, and to make significant changes without a ton of rework. I was actually surprised by this, because it is one of the first times where I've felt that the "Worse is better" UNIX mantra might actually have some merit to it!

More discussion about the design decisions I made while implementing this system is certainly welcome in the comments section, but for now let's take a look at what all those graphs have to say about my mood.

## Analyzing the results

The full report for my mood study consists of five different graphs generated via the R statistical programming language, each of which attempts to show a different perspective on the data:

* Figure 1 provides a summary view of the average mood ratings across the whole time period
(> 50 days of data)
* Figure 2 shows the daily minimum and maximums for the whole time period.
* Figure 3 shows the average mood rating and variance broken out by day of week
* Figure 4 breaks my day into five three-hour long segments and looks at the distribution of the different mood ratings in each segment.
* Figure 5 shows the average mood rating and variance on an hour-by-hour basis for both work days and rest days. 

The order above is the same as that of the PDF report, and it is essentially sorted by the largest time scales down to the shortest ones. Since that is a fairly natural way to look at this data, we'll discuss it in the same order in this article.

> **NOTE**: I've included implementation notes for each figure, which will hopefully be very interesting for folks who want to do data explorations of their own. That said, the notes are safe to skim or skip over entirely if you're just reading this article out of general curiosity.

---

**Figure 1 ([view source code](https://github.com/elm-city-craftworks/practicing-ruby-examples/blob/master/v7/003/moving-summary.R)):**

![Summary](http://i.imgur.com/1gr6BIF.jpg)

I knew as soon as I started working on this study that I'd want to somehow capture the general trend of the entire data series, but I didn't anticipate how noisy it would be to create a [plot with nearly 500 data points](http://i.imgur.com/NlIlgMI.png), many of which would prove to be too close together to visually distinguish from one another. To lessen the noise, I decided to plot a moving average instead of the individual ratings over time, which is what you see in **Figure 1** above.

It's important to understand the tradeoffs here: by smoothing out the data, I lost the ability to see what the individual ratings were at any given time. However, I gained the ability to easily discern the following bits of useful information:

* How my experiences over a period of a couple days compare to the global average (green horizontal line), and to the global standard deviation (gray horizontal lines). This information could tell me whether my day-to-day experience has been improving or getting worse over time, and also how stable the swing in my mood have been recently compared to what might be considered "typical" for me across a large time span.

* Whether my recent mood updates indicated that my mood was trending upward or downward, and roughly how long I could expect that to last.

Without rigorous statistical analysis and a far less corruptable means of studying myself, these bits of information could never truly predict my future or even be used as the primary basis for decision making. However, the extra information has been helping me put my mind in a historical perspective that isn't purely based on my remembered experiences, and that alone has turned out to be extremely useful to me.

> **Implementation notes ([view source code](https://github.com/elm-city-craftworks/practicing-ruby-examples/blob/master/v7/003/moving-summary.R)):**
>
> I chose to use an exponentially-smoothed weighted average here, mostly because I wanted to see the trend line change direction as quickly as possible whenever new points of data hinted that my mood was getting better or worse over time. There are lots of different techniques for doing weighted averages, and this one is actually a little more complicated than some of the other options out there. If I had to implement the computations myself I may have chosen a more simple method. But since an exponential moving average function already existed in the [TTR package](http://rss.acs.unt.edu/Rdoc/library/TTR/html/MovingAverages.html), it didn't really cost me any extra effort to model things this way.

>I had first seen this technique used in [The Hacker's Diet](http://www.fourmilab.ch/hackdiet/www/hackdietf.html), where it proved to be a useful means of cancelling out the noise of daily weight fluctuations so that you could see if you were actually gaining or losing weight. I was hoping it would have the same effect for me with my mood monitoring, and so far it pretty much has worked as well as I expected it would.

>
>It's also worth noting that in this graph, the curve represents something close to a continous time scale. To accomplish this, I converted the UNIX timestamps into fractional days from the moment the study had started. It's not perfect, but it has the neat effect of making it possible to see visible change in the graph after even a single new data point has been recorded.

---

**Figure 2 ([view source code](https://github.com/elm-city-craftworks/practicing-ruby-examples/blob/master/v7/003/daily-min-max.R)):**


![Min Max](http://i.imgur.com/wGdWN1J.jpg)

In a purely statistical sense, the highest and lowest values reported for each day might not be especially relevant. However, the nature of this particular study made me feel it was important to track them. After all, even if the "average" mood for two days were both around 7, a day where the lowest mood rating was a 1 will certainly be different sort of day than one where the lowest rating was a 5! For this reason, **Figure 2** shows the extreme high and low for each day in the study. This information is useful for the following purposes:

* Determining what my daily peak experiences are like on average. For example, we can see from this data that there was only one day where I didn't report at least a single rating of 7 or higher, and that most days my high point was either an 8 or 9. 

* Determining what my daily low points are like on average. Reading the data shown above, we can see that there were only three days in the entire study that I reported a low rating of 1, but that about one in five days had a low rating of 4 or less. 

* Visualizing the range between high and low points on a daily basis. This can be seen by looking at the space between the two lines: the smaller the distance, the smaller the mood swing for that day.

A somewhat obvious limitation of this visualization is that the range of moods recorded in a day do not necessarily reflect the range of moods actually experienced throughout that day. In most of the other ways I've sliced up the dataset, we can hope that averaging will smooth out some of the ill effects of missing information, but this view in particular can be easily corrupted by a single "missed event" per day. The key point here is that **Figure 2** can only be viewed as a rough sketch of the overall trend, and not a precise picture of day-to-day experience.

> **Implementation notes ([view source code](https://github.com/elm-city-craftworks/practicing-ruby-examples/blob/master/v7/003/daily-min-max.R)):**
>
> This was an extremely straightforward graph to produce using standard R functions, so there isn't too much to discuss about it. However, it's worth pointing out for folks who are unfamiliar with R that the support for data aggregation built into the language is amazing. Here is the code that takes the raw mood log entries and rolls them up by daily minimum and maximum:
>
> `data_max <- aggregate(rating ~ day, data, max)`
>
> `data_min <- aggregate(rating ~ day, data, min)`
>
> Because R is such a special-purpose language, it includes many neat data manipulation features similar to this one.

---

**Figure 3 ([view source code](https://github.com/elm-city-craftworks/practicing-ruby-examples/blob/master/v7/003/day-of-week.R)):**


![Day of week](http://i.imgur.com/qwytFft.jpg)

This visualization shows the mean and standard deviation for all mood updates broken out by day of week. Looking at my mood data in this way provides the following information:

* Whether or not certain days of the week have better mood ratings on average than others.
* Whether or not certain days of the week have more consistent mood ratings than others.
* What the general ups-and-downs look like on a typical week in my life

If you look at the data points shown in **Figure 3** above, you'll see that the high points (Monday and Friday) stand out noticeably from the low points (Wednesday and Saturday). However, to see whether that difference is significant or not, we need to be confident that what we're observing isn't simply a result of random fluctuations and noise. This is where some basical statistical tests are needed.

To test for difference in the averages between days, we ran a one-way ANOVA test, and then did a pairwise test with FDR correction. Based on these tests we were able to show a significant difference (p < 0.01) between Monday+Wednesday, Monday+Saturday, and Friday+Saturday. The difference between Wednesday+Friday was not significant, but was close (p = 0.0502). I don't want to get into a long tangent here because I fear it'll be distracting, but if you are curious about what the raw results of the computations ended up looking like, take a look at [this gist](https://gist.github.com/sandal/6147469).

> **Implementation notes ([view source code](https://github.com/elm-city-craftworks/practicing-ruby-examples/blob/master/v7/003/day-of-week.R)):**

> An annoying thing about R is that despite having very powerful graphing functionality built into the language, it does not have a standard feature for drawing error bars. We use a small [helper function](https://github.com/elm-city-craftworks/practicing-ruby-examples/blob/master/v7/003/helpers.R#L2-L5) to handle this work, which is based on code we found in [this blog post](http://bmscblog.wordpress.com/2013/01/23/error-bars-with-r ).

> Apart from the errorbars issue and the calls to various statistical reporting functions, this code is otherwise functionally similar to what is used to generate **Figure 2**.

---

**Figure 4 ([view source code](https://github.com/elm-city-craftworks/practicing-ruby-examples/blob/master/v7/003/frequency.R)):**


![Frequency](http://i.imgur.com/xTVfpRN.png)

Here we break the day into a total of five three-hour long segments and take a look at the distribution of ratings during those time periods. 

The graphs show that as time goes on throughout the day, the number of positive ratings (>= 6) decrease, and the number of of negative ratings (<= 5) increase, up until about 8pm, in which the pattern returns to something quite similar to what is observed in the morning.

The interpretation here is that as willpower is exhausted throughout the day, it becomes easier to have negative experiences. But after dinner and evening chores it's time for relaxation, and that "recharges" the batteries, so to speak. But this story doesn't necessarily match up with what the following graphs show.

TODO: Check frequency of five or lower (total percentage), see if there is a linear trend of decreasing from morning to 8pm, then increasing at the end.  

--- 

**Figure 5 ([view source code](https://github.com/elm-city-craftworks/practicing-ruby-examples/blob/master/v7/003/work-rest.R)):**


![Work days](http://i.imgur.com/a4Bh76u.png)

Here we see averages broken out by hour for days that I've set aside as work days. It shows that my most volitile time periods are from 9am-11am, from 4pm-6pm, and from 8pm-9pm. These mark the well-defined "transition" points of my day... from morning chores to work, from work to evening chores, and from evening chores to "rest".

-- consider showing transition points in different color. No stats are needed, just use a descriptive statement about the graph

![Rest days](http://i.imgur.com/oqNGYbJ.png)

Rest days are unfortunately all over the map, with high volitility at most times of the day, especially after 12:00pm and before 9:00pm. There are a number of factors that may come into play here, but one important may be that I have been much less reliable at recording updates during rest periods than I have been during my working time, and so this data may be less reliable and also biased towards extreme events.

However, there is also the factor that "rest days" often have me thinking about my work at inconvenient times and places, and that my own mood tends to mirror that of my son's if we're doing something together. Because the rest days don't have fixed "alone time", it's hard to maintain stability.

There is also a period of several days where we were experiencing major stress in my personal life, and that data could have easily skewed the whole dataset.

It'd be interesting to see whether this smooths out over time or not.

--TODO: Add an afterward with few days of really bad outliers omitted.

## Mapping a story to the data

* Happiest and most stable time of day is early morning and late evening
* (more things like this)

Remember -- take it all with a huge grain of salt, we're working backwards from observations to a model rather than the other way around.

(See notes below plus notes in my notebook)

Decreased sensitivity -- tired / overcommitted does not necessarily mean unhappy.

Talk about current deadline pressure and how I've been approaching it differently.


Observations (probably separate this out from method discussion above): My worst days (Wed / Sat) are also the most volitile. Those days have historically been "days off" for me, but the lower ratings might not be so easily explained by saying "I like to work more than I like to rest". Those days are also transition points between work and rest, so it may be the context switch that makes me unstable. My best days (Monday and Friday) correspond with when I tend to start something new, and when I tend to "wrap stuff up" for the week, like everyone else. (My weekend work tends to be more about pushing various existing things along rather than starting new stuff or finishing old stuff)

## Conclusion

Point out that this study is just one example of how we can explore data. Also point out that exploratory data analysis is a good precursor to doing classical analysis, because it helps you find interesting questions and consider how to model them before committing to a particular approach.  Plus, this is fun!

Talk about the remembering mind as a glib salesman trying to tell a particular story. Data doesn't stop him from influencing you, but it might help keep him on point, and even may expose areas where he's obviously bullshitting you. This can give you leverage in decision making, because it's the job of the experiencing mind to do that!

(NB: RStudio is awesome)


---



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

