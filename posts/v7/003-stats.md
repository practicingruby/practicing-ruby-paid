1. individual days, relationship between mood and time of the day
patterns.
days break into 3 hours 8am to 11pm, 15 hours.
8-11, 11-2, 2-5, 5-8, 8-11.

2. work day or rest day, mood difference

3. the drag effect, if there is a number stands out background, find outlier 
(<3 or >8), take n (maybe 10) data points around it, average different from 
global average?

4. periods of time, mood alleviated or depressed for a couple days?
day average, the drag effect

5. cycles. FFT on day averages


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

