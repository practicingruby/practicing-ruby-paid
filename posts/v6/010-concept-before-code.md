 > **NOTE:** This issue of Practicing Ruby one of several experiments
> to be published in Volume 6. It intentionally breaks away from the traditional
> article format that we have developed over the years in the hopes of finding
> new and interesting ways for you to level up your programming skills. The
> primary purpose of these experiments is to get feedback from our readers, so
> please do share your thoughts about each of them!

In this article, we'll attempt a repeat experiment of the recipe-style format
that was first used in [Issue 6.6](https://practicingruby.com/articles/103). 
You'll find that the content that follows is much shorter than 
the average Practicing Ruby article, while maintaining a similar level of
density. Please leave a comment letting me know whether you like this style or
not, and what suggestions you might have for improving it!

---

**Problem: It is very easy to sink a large amount of time and effort into a side
project before discovering the core problems that need to be solved.**

There are lots of reasons to work on side projects, but there are two that stand
out above the rest: scratching a personal itch by solving a real problem, and 
gaining a better understanding of various programming tools and techniques.
Because these two motivating factors are competing interests, it pays to set
explicit goals before working on a new side project.

Remembering this lesson is always a constant struggle for me, though. 
Whenever I'm brainstorming about a new project while taking a walk or sketching
something on a white board, I tend to dream big, ambitious dreams that extend far
beyond what I can realistically accomplish in my available free time. To show
you exactly what I mean, I can share the back story on what that lead me to 
write the article you're reading now:

> Because I have a toddler to take care of at home,
meal planning can been a major source of stress for me. My wife and I are 
often too distracted to do planning in advance, so we often need to make a 
decision on what to eat, put together a shopping list, go to the grocery 
store, and then come home and cook all in a single afternoon. 
Whenever this proves to be too much of a challenge for us, we order 
takeout or dig out some frozen junk food. Unsurprisingly,
this happens far more often than we'd like it to.

> To make matters worse, our family cookbook has historically consisted of a 
collection of haphazardly formatted recipes from various different sources. Over time, we've
made changes to the way we cook these recipes, but these revisions almost
never get written down. So for the most part, our recipes are inaccurate, 
hard to read, and can only be cooked by whichever one of us knows its quirks.
Most of them aren't even labeled with the name of the dish, so you need to
skim the instructions to find out what kind of dish it is!

> On one of my afternoon walks, I decided I wanted to build a program
that would help us solve some of these problems, so that we could make fewer
trips to the grocery store each week, while reducing the friction and cognitive
load involved in preparing a decent home cooked meal. It all seemed so simple in
my head, until I started writing out my ideas!

By the time I got done with my brain dump, the following items were on the 
wish list of things I wanted to accomplish in this side project:

* I figured this would be a great time to try out Rails 4, because this project
would obviously need to be a web application of some sort.

* It would be another opportunity for me to play around with Twitter Bootstrap.
I am weak at frontend development, but I am also bothered by poor visual 
design and usability, so it seems to be a toolset that's worth learning for
someone like me.

* I had been meaning to figure out a way to use the Pandoc toolchain from Ruby to 
produce HTML and PDF output from Markdown formats, so this would be a perfect 
chance to try that out, because I'd need my recipes to be viewable on the web 
and in a printable format.

* It would be really cool if the meal planner would look for patterns in our
eating habits and generate recommendations for us once it had enough data to
draw some interesting conclusions.

* It would be nice to have a way of standardizing units of measures so that we
could trivially scale recipes and combine multiple recipes into a shopping list
automatically.

* It would be neat to support revision control and variations on recipes within
the application, in addition to basic CRUD functionality and search.

* It would be awesome to be able to input a list of ingredients we have on hand
and get back the recipes that match them.

I won't lie to you: the system described above still sounds awesome to
me, both because it'd involve lots of fun technological challenges, and because
it'd be amazing to have such a powerful tool available to me. But it also
represents a completely unreasonable set of goals for someone who has so little
productive free time that even cooking dinner seems like too much work.

So my initial brainstorming session proved to be a nice day dream, but 
it wasn't a real solution to my problems. Instead, what I needed was an approach 
to this problem that could deliver modest results in fractions of an hour 
rather than in days and weeks. To do that, I'd have to radically scale back my
expectations and set out in search of some low hanging fruit.

---

**Solution: Build a single useful feature and see how well it works in practice 
before attempting to design a full-scale application or library.**


- Develop concept before code
- Automate a tiny portion of the problem and focus on pain points rather than "features"
- Incrementally optimize to eliminate pain points (through BOTH automation and process revision)
- Avoid dealing with lots of dependencies, and introducing excess process/structure before you can evaluate its value.
- Smaller risks are easier to take without regret, a low time investment to make a small improvement is always worth it.
- Less time programming, more time solving problems

- Discover the cost of markdown formatting / benefits of recipes under revision
  control (no longer read only!)

Can be edited via a spreadsheet or in a text editor
Will be easy to import into a real database later.

Started with 16 recipes from the cookbook, labeled them with a marker...

```
name,label
"Veggie Cassarole w. Swiss Chard + Baguette",1
"Stuffed Mushroom w. Leeks + Shallots",2
"Lentil Soup w. Leeks + Kale",3
"Spinach + White Bean Soup",4
```


```
name,label,effort
"Veggie Cassarole w. Swiss Chard + Baguette",1,3
"Stuffed Mushroom w. Leeks + Shallots",2,3
"Lentil Soup w. Leeks + Kale",3,3
"Spinach + White Bean Soup",4,2
```

```ruby
require "csv"

candidates = []

CSV.foreach("recipes.csv", :headers => true) { |row| candidates << row }

puts "How about this menu?\n\n" + candidates
  .sample(3)
  .map { |e| "* #{e['name']} (#{e['label']})" }
  .join("\n")
```

Ignoring the suggestions because of too few meals in data set (duplicates or
recently eaten meals came up often), and no difficulty filtering.

```ruby
require "csv"

candidates = []
effort     = ARGV[0] ? Integer(ARGV[0]) : 3

CSV.foreach("recipes.csv", :headers => true) { |row| candidates << row }

puts "How about this menu?\n\n" + candidates
  .select { |e| Integer(e['effort']) <= effort }
  .sample(3)
  .map { |e| "* #{e['name']} (#{e['label']})" }
  .join("\n")
```


```ruby
require "sinatra"
require "csv"

def meal_list(candidates, effort)
  "<ul>" + 
    candidates.select { |e| Integer(e['effort']) <= effort }
              .sample(3)
              .map { |e| "<li>#{e['name']} (#{e['label']})</li>" }
              .join + 
  "</ul>"
end

get "/" do
  candidates = []
  effort     = Integer(params.fetch("effort", 3))
  meal_list  = "#{File.dirname(__FILE__)}/../recipes.csv"

  CSV.foreach(meal_list, :headers => true) do |row| 
    candidates << row 
  end

  @selected = meal_list(candidates, effort)
  
  erb :index
end

__END__

@@index
<html>
  <body>
    <h1>How about these meals?</h1>
    <%= @selected %>
  </body>
</html>
```

Examples:

- Started with a simple CSV file with names and numbers that reference recipes in a physical book
- Experimented with markdown files and manually rendering them via pandoc
- Realized that time-based filtering is important: a 20 minute meal is not the same as a 1.5 hour meal, but if you let your stomach decide you may end up with the latter when you really need the former.
- Realized that not all meals need a "recipe" -- simple things like sandwiches or pre-bought stuff from store
- Realized that having the recipes in "source code" format is hugely valuable --
  why do we treat recipes as read-only when we should really be editing them to
  tweak ingredients, amounts, times, etc. Now each time I cook I take notes and
  revise. (git + raw markdown proves to be more than enough here)

---

**Discussion**

The bulk of our problem was organizational / human, not technical. So it paid to
take an approach that focuses more on the functional problem than the technical
issues.

Supporting materials:  
  
BTree insurance selection anecdote
ShipIt Anecdote
XKCD automation table
http://www.eatthismuch.com/
