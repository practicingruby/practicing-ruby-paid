**IMPORTANT: You'll need to find a way to write this while minimizing references
to "Programming Erlang" text and code**

http://css-tricks.com/words-avoid-educational-writing

- Demonstrate a day-by-day summary of the high level concepts learned (and how
  they might compare to Ruby), then illustrate concrete concepts learned
  via code samples (especially look for tangents outside of the book,
  i.e. book says X, but I want to know if X implies Y).

- Read the entire JOURNAL.md file and then update this manuscript with notes
  before you start writing.

- Make sure to discuss the hows and whys of the learning process in addition to
  just what I did. (See for example notes on January 5 about deliberate
  reading). The PR article should be a structured guide to how to learn with 
  my example as a case study, not just a stream-of-consciousness "how I learned"
  piece. Synthesize everything, don't just quote raw notes or repeat
  the PE narrative / example structure.

- Come up with 3-4 questions that this article must answer, and destroy anything
that does not serve those questions. This article in particular should be
as tight as possible.

- Discuss my previous experiences with learning Erlang (get the book and work
  through the first couple chapters excitedly, then just stop without ever
  really building anything... random hacks across the years that never got
  finished, constantly struggling with syntax and basic idioms, even
  if I knew the broad concepts and costs/benefits of the language,
  and could kind-of read it -- reading is much easier than writing!)

- For learning how to read, exercise like (ANT SIM) is good. To learn how to
write, approach needs to be different. Perhaps obviously, you need to spend
more time writing than reading, and you need a good reference to cover
minute details so you don't keep getting snagged. Repetition is also important.

- Discuss what I learned about Erlang in preliminaries, and importance of doing
preliminary phase (this is mentioned in Checklists.MD)

- Discuss why the different segments, i.e. exercises for warmup, reading,
  projects, planning / reflection. What can each teach you?

- Point out that writing this article was a valuable practice exercise 
for me, too.

- Summarize what I learned in the preliminary and pracrice week, and also what
  my next steps would be if I kept studying. Explain that it's like trying to
  make the first cut into a boulder, and that from there you can always
  divide-and-conquer.

### Learning advice

- You can and should lookup outside documentation while reading a book, as well
  as code samples, etc. No article or book is truly self-contained.

- Have a sense of *why* you want to learn more about a language. For me, I was
  interested in Erlang's concurrency, fault tolerance, and pattern matching
  features.

- Type every code sample, don't just copy and paste. It's one of the best ways to
drill syntax rules into your head, as well as to practice working and memorizing
language primitives. It really slows down your thought process too, forcing you to spend
a lot more time with each code sample. Typing code in as you read also gives you
an opportunity to go off on tangents (see import example in Journal from Jan 6) 
or clarify concepts that you might otherwise skip over if you are just reading 
the code. Finally, it will help you recognize whether a code sample has all 
of its necessary boilerplate or if some other code is omitted (and in order 
to make it run, you'll learn what that boilerplate is). For example, typing 
out examples got me familiar with Erlang's module organization in just a 
few code samples.

- Work on problems that are familiar to you, at least at first. This way you
  won't end up confusing problems related to holes in your understanding of a
  language with holes in your understanding of the problem you're working on.
  Also, you will reduce the opportunities to get stuck, and drive down
  overall frustration. This will let you pour all your energy into learning
  the language you're studying. (For the same reason, preliminary practice
  is worthwhile). 
  
- As you gain more experience you can and should venture into
  uncharted territory (especially problems well suited for the language you're
  studying, as well as problems well-suited for languages you're comfortable
  with (so that you can see how well the new language can solve them). But
  it is good to alternate between trying new stuff and working on problems
  you already know how to solve.

- There is a huge difference between being able to read code in a language
  and being able to write code. They're both useful skills, but the latter
  involves a lot more deliberate practice by necessity (both can benefit
  from it of course).

- Take a TON of notes, don't worry if you'll use them later or not, and don't
  worry too much about making them perfect, as long as they reflect your
  current understanding. The process of writing down your ideas helps refine 
  your thoughts, even if you don't end up using your notes for reference later.

- It's better to use self-discipline to work through a practice session while
resisting distractions than it is to alternate between distractions and focused
work, but if that's not possible, stop the timer, and take as long of a break
as you need before getting back into focused work.

- Don't worry at all about elegance and don't even be too worried about
  correctness. Build something that "sort of works", and then refine it as your
  knowledge expands or as the particular topic covered by the code becomes more
  important to you. Every piece of code is an artifact that grows your general
  understanding of a language and also reflects your current mental model (which
  will need constant refining), so simply writing code that runs and kind of
  does what you want it to is all that matters, you can build a step-ladder
  upward and outward from there.
