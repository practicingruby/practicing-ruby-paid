
The program starts off by defining some of the parameters that the simulation
depends upon:

```clojure
;dimensions of square world
(def dim 80)
;number of ants = nants-sqrt^2
(def nants-sqrt 7)
;number of places with food
(def food-places 35)
;range of amount of food at a place
(def food-range 100)
;scale factor for pheromone drawing
(def pher-scale 20.0)
;scale factor for food drawing
(def food-scale 30.0)
;evaporation rate
(def evap-rate 0.99)

; ... a few more similar definitions follow
```

Virtually every language has a number of ways to map names to values, and
Clojure is no exception. Although the [exact semantics of def][def] cannot be
gleaned from this example, we're able to roughly guess that these are
named constants, and that's all we need to know for now.

Immediately following the parameter definitions is a slightly more interesting
statement which defines the structure of cells:

```clojure
(defstruct cell :food :pher) ;may also have :ant and :home
```

If we take this line of code at face value, Clojure's structs sound like they might 
be something in between Ruby's `Struct` and `OpenStruct`. They are clearly
similar to `Struct` in that field names can be explicitly defined, but the
comment hints that additional fields can be added later. A quick skim through
the [documentation for the StructMap data structure][struct] confirms
these assumptions, but it also invites us to get bogged down in details
that aren't terribly important to us at the moment. Let's keep moving forward
and figure things out as we go.

The next bit of code introduces several new concepts, so we'll need to slow our
pace a bit:

```clojure
;world is a 2d vector of refs to cells
(def world 
     (apply vector 
            (map (fn [_] 
                   (apply vector (map (fn [_] (ref (struct cell 0 0))) 
                                      (range dim)))) 
                 (range dim))))
```

According to Clojure's documentation, a [Vector][vector] is a collection of
values indexed by contiguous integers, and a [Ref][ref] is a *transactional
reference* that is used for ensuring safe shared use of mutable storage. The
former structure is at least superficially similar to Ruby's `Array` object, but
the latter is a low-level concurrency primitive that does not have a direct
counterpart in Ruby. Fortunately, the documentation about [Refs and
Transactions][ref] is quite good, even if you're an absolute beginner to the
topic. While it's worth reading the whole page, this paragraph describes the
*Software Transactional Memory* concept in a nutshell:

> Clojure transactions should be easy to understand if you've ever used database
> transactions - they ensure that all actions on Refs are atomic, consistent,
> and isolated. Atomic means that every change to Refs made within a transaction
> occurs or none do. Consistent means that each new value can be checked with a
> validator function before allowing the transaction to commit. Isolated means
> that no transaction sees the effects of any other transaction while it is
> running. Another feature common to STMs is that, 
> should a transaction have a conflict while running, it is automatically retried.

If we look back at the last code sample, it is clear that it constructs something
akin to a two-dimensional array of thread-safe cell structs. However, if like me
you've never done much more than write a "Hello World" program in Clojure, you
might still find the example hard to read. A bit of experimentation via
Clojure's REPL can really help clear things up:

```clojure
user=> (defstruct cell :food :pher) 
#'user/cell
user=> (struct cell 0 0)                  ; # 1
{:food 0, :pher 0}
user=> (range 10)                         ; # 2
(0 1 2 3 4 5 6 7 8 9)
user=> (map (fn[x] (* x 2)) (range 10))   ; # 3
(0 2 4 6 8 10 12 14 16 18)
user=> (vector 1 2 3)                     ; # 4
[1 2 3]
user=> (vector [1 2 3])                   ; # 5
[[1 2 3]]
user=> (apply vector [1 2 3])             ; # 6
[1 2 3]
```

From these simple examples, we can infer the following points:

1. The [struct][struct] function is used to construct a new StructMap instance.

2. The [range][range] function supports features similar to Ruby's
`Integer#times` enumerator.

3. Clojure's [map][map] function is similar to Ruby's
`Enumerable#map` method.

4. The [vector][vector] function creates a new Vector object with the arguments
as its elements.

5. `Vector` objects can be nested within each other.

6. The [apply][apply] function is basically equivalent to the splat operator
(*args) in Ruby.

Now that we are familiar with few more Clojure features, we can imagine what this 
`world` function would look like in Ruby syntax:

```ruby
def world
  DIM.times.map do
    DIM.times.map do
      # pretending as if we had Clojure-like Ref objects in Ruby ;-)
      Ref.new(Cell.new(0, 0)) 
    end
  end
end
```

This code looks a bit more concise in Ruby, but it's because something was lost
in translation. Take a closer at the Clojure version to see if you can figure
out what it is:

```clojure
(def world 
     (apply vector 
            (map (fn [_] 
                   (apply vector (map (fn [_] (ref (struct cell 0 0))) 
                                      (range dim)))) 
                 (range dim))))
```




[def]: http://clojure.org/special_forms#Special%20Forms--%28def%20symbol%20init?%29
[struct]: http://clojure.org/data_structures#Data%20Structures-StructMaps
[vector]: http://clojure.org/data_structures#Data%20Structures-Vectors%20%28IPersistentVector%29
[ref]: http://clojure.org/refs
[map]: http://clojure.github.com/clojure/clojure.core-api.html#clojure.core/map 
[range]: http://clojure.github.com/clojure/clojure.core-api.html#clojure.core/range
[struct]: http://clojure.github.com/clojure/clojure.core-api.html#clojure.core/struct
[vector]: http://clojure.github.com/clojure/clojure.core-api.html#clojure.core/vector
[apply]: http://clojure.github.com/clojure/clojure.core-api.html#clojure.core/apply

- http://tryclj.com/
- brew install clojure
- VimClojure
- clojure-rlwrap

http://blog.fogus.me/2009/09/04/understanding-the-clojure-macro/
http://lethain.com/a-couple-of-clojure-agent-examples/

# ..........

http://ai-depot.com/Essay/SocialInsects-Ants.html
http://en.wikipedia.org/wiki/Conway%27s_Game_of_Life
http://en.wikipedia.org/wiki/Boids
http://en.wikipedia.org/wiki/Ant_colony_optimization_algorithms
http://www.youtube.com/watch?feature=endscreen&NR=1&v=SMc6UR5blS0
http://www.youtube.com/watch?v=vAnN3nZqMqk&feature=related
AntSim
