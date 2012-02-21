In [Issue 3.7](http://practicingruby.com/articles/24) I started to explore the criteria laid out by M. Sakkinen's
[Disciplined Inheritance](http://scholar.google.com/scholar?cluster=5893037045851782349&hl=en&as_sdt=0,7&sciodt=0,7), 
a language-agnostic paper published over two decades ago that is surprisingly 
relevant to the modern Ruby programmer. In this issue, we continue where Issue 3.7 
left off, with the question of how to maintain complete compatibility between
parent and child objects in inheritance-based domain models. Or put another way,
this article explores how to safely reuse code within a system
without it becoming a maintenance nightmare.

After taking a closer look at what Sakkinen exposed about this topic, I came to
realize that the ideas he presented were strikingly similar to the [Liskov Substitution
Principle](http://en.wikipedia.org/wiki/Liskov_Substitution_Principle). In fact,
the extremely dynamic nature of Ruby makes 
establishing [a behavioral notion of sub-typing](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.39.1223) (Liskov/Wing 1993)
a prerequisite for developing disciplined inheritance practices. 
As a result, this article refers to Liskov's work moreso than Sakkinen's, 
even though both papers have extremely interesting things to say about this topic. 

### Defining a behavioral subtype 

Both Sakkinen and Liskov describe the essence of the inheritance relationship as 
the ability for a child object to serve as a drop-in replacement wherever
its parent object can be used. While I've greatly simplified the concept by
stating it in such a general fashion, this is the common thread which ties
their independent works together. 

Liskov goes a step farther than Sakkinen by defining two kinds of 
behavioral subtypes: children which extend the behavior specified by their 
parents, and children which constrain the behavior specified by their parents. 
These concepts are not mutually exclusive, but because each brings up
its own set of challenges, it is convenient to split them out in this
fashion.

Both Sakkinen and Liskov emphasize that the abstract concept of subtyping 
is  much more about the observable behavior of objects than it is about
what exactly is going on under the hood. This is a natural way of thinking
for Rubyists, and is worth keeping in mind as you read through the rest
of this article. In particular, when we talk about the type of an object,
we are focusing on what that object *does*, not what it *is*.

While the concept of a behavioral subtype sound like a direct analogue for
what we commonly refer to as "duck typing" in Ruby, the former is about
the full contract of an object, rather than how it acts under certain
circumstances. I go into more detail about the differences between
these concepts (and their trade-offs) towards the end of this article,
but before we can discuss them meaningfully, we need to take a look
at Liskov's two types of behavioral subtyping and how they can
be implemented.

### Behavioral subtypes as extensions

### Behavioral subtypes as restrictions

### Relating behavioral subtypes to duck typing

### Reflections

---

> _A subtype is completely compatible with its supertype if it has the same
> domain as the supertype and, for all operations of the supertype,
> corresponding arguments yield corresponding results._

This is meant to imply that the subtype covers at *least* the domain of the
supertype, new behavior can be added. This implies a child object can be used
anywhere a parent object was expected. **This all boils down to LSP**

Rules to ensure complete compatibility:

In the trivial case of delegation with no modifications, CC is trivial.

In the non-trivial case, in practice it means we need to:

1) Each method the child object wraps must invoke the parent object method
   it is wrapping and return its result. The child object should not otherwise
   modify the parent object in any way. **think about whether duck typing is
   relevant here**, can you augment the return value as long as you remain
   compatible with the original return value?

2) No operation in the child object may directly invoke state-modifying private
   functions of its parent object.

**To support late binding, a LoD violation is necessary**. Is late binding evil?

NOTES: 

1) Completely compatible inheritance seems to be a risk for anything that might
be volatile in nature. Where do we draw the line?

2) From wikipedia on
[LSP](http://en.wikipedia.org/wiki/Liskov_substitution_principle):

> History constraint (the "history rule"). Objects are regarded as being modifiable only through their methods (encapsulation). Since subtypes may introduce methods that are not present in the supertype, the introduction of these methods may allow state changes in the subtype that are not permissible in the supertype. The history constraint prohibits this. It was the novel element introduced by Liskov and Wing. A violation of this constraint can be exemplified by defining a MutablePoint as a subtype of an ImmutablePoint. This is a violation of the history constraint, because in the history of the Immutable point, the state is always the same after creation, so it cannot include the history of a MutablePoint in general. Fields added to the subtype may however be safely modified because they are not observable through the supertype methods. One may derive a CircleWithFixedCenterButMutableRadius from ImmutablePoint without violating LSP.

3) References

* http://www.objectmentor.com/resources/articles/lsp.pdf [BOB MARTIN: READ THIS]
* http://www.cs.cmu.edu/~wing/publications/LiskovWing94.pdf [LISKOV/WING]
* http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.12.819&rep=rep1&type=pdf

4) Liskov substitution principle

"A typical example that violates LSP is a Square class that derives from a
Rectangle class, assuming getter and setter methods exist for both width and
height. The Square class always assumes that the width is equal with the height.
If a Square object is used in a context where a Rectangle is expected,
unexpected behavior may occur because the dimensions of a Square cannot (or
rather should not) be modified independently. This problem cannot be easily
fixed: if we can modify the setter methods in the Square class so that they
preserve the Square invariant (i.e., keep the dimensions equal), then these
methods will weaken (violate) the postconditions for the Rectangle setters,
which state that dimensions can be modified independently. Violations of LSP,
like this one, may or may not be a problem in practice, depending on the
postconditions or invariants that are actually expected by the code that uses
classes violating LSP. Mutability is a key issue here. If Square and Rectangle
had only getter methods (i.e., they were immutable objects), then no violation
of LSP could occur."

