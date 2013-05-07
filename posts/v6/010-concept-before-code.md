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

Had a very complicated vision of an interesting program:

- Add/edit/view/download as PDF recipes
- Randomly assemble a 3 day menu on demand
- produce a shopping list for all dishes on menu
- Use a standard format and template for recipes

But this requires:

- a web app (probably rails)
- a database model
- a stylized front-end, etc.

Problem: Awesome, but exhausting, and uncertain payoff.

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

```ruby
require "csv"

candidates = []

CSV.foreach("recipes.csv", :headers => true) { |row| candidates << row }

puts "How about this menu?\n\n" + candidates
  .sample(3)
  .map { |e| "* #{e['name']} (#{e['label']})" }
  .join("\n")
```

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
- Realized that having the recipes in "source code" format is hugely valuable -- why do we treat recipes as read-only when we should really be editing them to tweak ingredients, amounts, times, etc. Now each time I cook I take notes and revise.

---

**Discussion**


Supporting materials:  
  
BTree insurance selection anecdote
ShipIt Anecdote
XKCD automation table
http://www.eatthismuch.com/
