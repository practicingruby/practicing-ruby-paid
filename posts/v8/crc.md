# Sources

* Cunningham / Beck on CRC
* GOOS
* Wirfs-Brock + Wilkerson "OO Design, a responsibility driven approach"
* Object-oriented brewery

----

# Wirfs-Brock + Wilkerson "OO Design, a responsibility driven approach"

* Interesting that the paper basically says Data-driven design = ADT design,
which historically explains why C++/Java style OO is so different than
Smalltalk style OO.

* Questions for ADT design:

1) What data does this type subsume?
2) What algorithms can be applied to this data?

* Questions for Data-driven design:

1) What structure does this object represent?
2) What operations can be performed by this object?

* Questions for Responsibility-driven design:

1) What actions is this object responsible for?
2) What information does this object share?

* Unsure about the two RasterImage examples... is the difference
that the responsibility-driven one introduces more abstract
objects? (i.e. Rectangle, Shape) and query methods (i.e. visibleAt()),
allowing it to be interacted with at a higher level of abstraction?
This is different than other "responsibility driven" examples I've
seen, in that it looks like more of a contrast between primitive
functions and high level functions than anything else.

> "Encapsulation is compromised when the structural details of an object become
> part of the interface to that object. This can only occur if the designer
> uses knowledge of those structural details. Responsibility-driven design
> maximizes encapsulation when the designer intentionally ignores 
> this information.

# Object-oriented brewery

Four main approaches to object-oriented development:

* data driven
* process driven
* event driven
* responsibility driven

> "Analysis says what a system is supposed to do, and design says how it it is
> supposed to do it."

In responsibility-driven design,
Scenarios (use cases) form the basis for coming up with classes and their responsibilities
/ collborations. Basic process is to come up wtih a common vocabulary for describing
the problem and then walk through the scenarios and compare them to the object designs,
refining where needed.

(NOTE: Maybe this means if you're having trouble writing CRC cards, try to go back
and write up your use cases in more specific and clearer detail?)

((Look deeper into the separation between design and analysis in this paper))

In data-driven design, there isn't much of a distinction between the analysis
and design phase except to consider issues like performance, lack of
language/framework support for needed features, hardware, external software
interfaces, etc.

Responsibility driven design requires a more active process of redefining objects,
streamling collaborations, redistributing responsibilities, formalizing and refining
responsibilities, grouping functionality / creating hierarchies, etc.

((( Could this be an important distinction between the two techniques? In data-driven
style that I'm familiar with... you build a bunch of "bricks", and then the messy
/ hard part is writing the procedural code to glue it all together. But in responsibility-driven
code you give up that central control, and so it's distributed to all the boundary lines
between the objects... making it a concern up front rather than a gradually building
ball of mud)))

*Awesome set of scenarios for the brewery. Note the high level they're specified at,
broader scoped than what I'd usually write use cases at --- Maybe too fine-grained
is bad for responsibility-driven development???*

**Object oriented complexity metrics**

* Weighted methods per class
* Depth of tree inheritance
* Number of children
* Coupling between objects
* Response for a class
* Lack of cohesion in methods

* Weighted attributes per class
* Number of tramps

* Violations of the law of demeter

(Dig deeper into paper for the precise definitions of these metrics,
which can be useful for having a concrete context for discussion,
and for comparing techniques)

Responsibility driven design scored lower on all metrics,
with the most significant differences found for coupling,
cohesion, and LoD violations.

(See Figure 4.2-1 and 4.2-2 for an interesting difference in topological
layout between data-driven and responsibility-driven designs... in
particular former is flat and the latter is layered, and in the data-driven
design data is not colocated with algorithm, whereas in the responsibity-driven
design it is.)

> Controlling classes must acquire necessary information from other
> classes and controlled classes keep information for other classes to use.
> Thus the presence of "controlling" and "controlled" classes is essentially
> a manifestation of the poor encapsulation of those classes.

((Figure 4.2-3 shows exactly what I've seen happen in my design, lots of
simple data objects with low coupling, and then a handful with massive
coupling, and similar results for cohesion))

((*Paper claims it's generally better to have a deep inheritance hierarchy
than it is to have many children of a given class (depth better than
breadth), and claims that data-driven design does the opposite. I need
to think on this more, especially when we replace inheritance with 
composition-based modeling*))

Major argument basically boils down to "responsibility-driven design inherently
encourages colocation of data and action (encapsulation), whereas data-driven
design undermines encapsulation. Will need to think on this more. Strongest
point is the danger of "controlled" and "controlling" classes, but authors
discussed little about the downsides of responsibility-driven design.

---

> What we often do is "procedural programming with objects" or
> "functional programming with objects" or "Java/C++ something-something classes"
> For me personally, the idealized object-oriented approach (message-passing, responsibility oriented style)
> is very appealing, but very hard to think naturally about. The CRC method is about
> putting that kind of thinking into practice, and so it's a good tool for
> trying out these kinds of ideas.

## TODO MAKE APP AS EASY TO INSTALL AS POSSIBLE, WITH ALL INSTRUCTIONS
## NEEDED TO GET RUNNING ON HEROKU.

Possible theme, from paper:

> We have also asked skilled object programmers to try using CRC cards. 
> Our personal experience suggests a role for cards in software engineering 
> though we cannot yet claim a complete methodology (others [5][6] have more 
> fully developed methodologies that can take advantage of CRC methods).

(dig into references)
 
----


Working w. CRC cards and doing responsibility-centric design pretty much go hand 
and hand which is challenging if you're used to a data-centric view of things.

(mention how diff people do their class designs based on Deep Read discussion)
Note how unnatural this is for me because I'm always just hacking scripts
and spike solutions.

Initial use case:

> Student visits submissions page, uploads a zip file of their entrance 
exam source code, and then is shown a status page where they
can check back later to see the status of their submission.

> If anything goes wrong, fail gracefully and allow restarting the process.

Initial attempt at a card:

> ExamUploader
>   R: Upload entrance exame
>   R: Generate secret code
>
>   C: ??? (No idea on a first pass)

Second attempt:

> EntranceExam
>   R: Upload source code
>   R: Download source code
>   R: Generate secret key
>   R: Track status (pending, under review, accepted, ...)
>
>   C: ??? (No idea again)

Third attempt:

> ExamSubmission
>   R: Use a secret code to retrieve status of exam and attached source code
>   
>   C: ExamSourceCode
>
> ExamSourceCode
>   R: Store uploaded zip file
>   R: Retrieve uploaded zip file

Fourth attempt

Started to work on another card set and then realized that dealing with 
download links is out of scope of the use case, and even displaying fine
grained status is a bit premature. The real use case is more like this:

> Student uploads submission. If upload succeeds, display a "success"
page and remind them to bookmark it and check back later for status
updates. If upload fails, show an error message and ask them to try
submitting again.

With this in mind, I end up with the following cards:

> ExamUploader
>   R: Uploads zip file
>   R: Generates random key on successful upload
>   R: Reports errors on upload failure
>
>   C: SubmissionPresenter

> SubmissionPresenter
>   R: Prepares submission status for views
>   R: Prepares error messages (if any) for view
>   R: Provides query method for determining error state

> SubmissionController
>   R: Accepts uploaded files from request
>   R: Prepares ExamPresenter for view
>
>   C: SubmissionPresenter
>   C: ExamUploader



This still all feels a bit awkward to me. The controller
is sort of repetitive with the other cards, and
responsibilities like "provides query method for..." sound
like recasting procedural thinking in an object-oriented cloak.

At this point, I feel the need to drop down to the code level
to see what comes out from it. I can always redesign later.


* Need to get set up with S3, never done this before
* Need to get a Rails app up and running on Heroku
* Need to select a file uploads library... attempting to use
`refile`.

Total time to set up with all of the above is already MUCH
more than the design time, so it's not like the design
time was expensive. If it helps AT ALL, it's worth doing.

(a half hour vs. 90 mins or so)


Uploading solution
```
>> submission = Submission.new
=> #<Submission id: nil, exam_zipfile_id: nil, status: nil, code: nil, created_at: nil, updated_at: nil>
>> submission.code = TokenPhrase.generate(:numbers => false)
=> "free-range-cerulean-argyle-fork"
>> submission.exam_zipfile = StringIO.new("Hello from ActiveRecord")
=> #<StringIO:0x000001010fec20>
>> submission.save
>> exit
```

Retrieving from S3
```
>> Submission.find_by(:code =>  "free-range-cerulean-argyle-fork")
=> #<Submission id: 1, ...>
>> submission = Submission.find_by(:code =>  "free-range-cerulean-argyle-fork")
>> submission.exam_zipfile.read
=> "Hello from ActiveRecord"
```

Another thing I noticed is that by doing a little bit of design work up front,
most of the Rails boilerplate seemed to go a little smoother. It felt more
like a routine chore, where what I typically do alternate between getting the
app set up and thinking about what the first feature would look like
(code wise), and that splits my focus. Having a very basic outline
in place helped keep my mind trained on an end-result, and so it felt
less stop-and-go.

----

First crack at an "ExamUploader" doesn't really resemble the CRC card I wrote,
but it is influenced by it:

```ruby
class ExamUploader
  def self.upload(zipfile)
    submission = Submission.new(:exam_zipfile => zipfile)
    submission.code = TokenPhrase.generate(:numbers => false)

    if submission.valid?
      submission.save
      { :status => :success, :code => submission.code }
    else
      { :status => :error, :errors => submission.errors.full_messages }
    end
  end
end
```

I'm still in a very data-driven mindset, so I'll need to think on how to turn
this into a message passing / responsibility-driven style. Even still, this
gets part of the way there in that it does good data hiding (input is a simple
file object, output is a primitive hash)

I'm unsure if the data object (Submission) should be used as-is, injected in
as an abstract dependency, or if the object itself is not designed properly
for responsibility driven style. I.e. should ActiveRecords show up as collaborators,
or do we treat them as internals? (and what are the tradeoffs)

Orthodoxy doesn't matter here, but having coherent rules is important if you're
going to try to adopt a particular design style. What matters is internal
clarity / consistency, and I'm not sure what rules I should apply here.

It was absolutely critical for me to build a walking skeleton that I could
manually interact with via the browser... even if it's just a throwaway
proof of concept. This is a challenge for me in that I can't do much paper
design at all without feeling a strong urge to write code.

----

Idea:

Turn the code below (which I had a typo that caused a bug (:failure instead of :error)

```
- case @results[:status]
- when :success
  = @results[:code]
- when :error
  ul
    - @results[:errors].each do |e|
      li= e
```

Into this:

```
- submission.on_success do
  = submission.code

- submission.on_failure do
  ul
    - submission.errors.each do |s|
      li s

- submission.render
```

(Not necessarily a good idea, but worth trying... compare tradeoffs to case statement (missing else caused null behavior))

----

See discussion with Jacob from 2015-01-05 and this gist:
https://gist.github.com/sandal/b4e0d192ac048c7a4c88

Weird naming issues, for example I call the SubmissionPresenter a 'view' in one place,
but a 'submission' in another, and it's neither.

Code is closer to the original CRC cards now, but different than how I imagined it.
More weird/different than bad, will need to think more about pros and cons,
and also see how it Evolves to support future use cases.

----

The CRC card set was useful in that it revealed the awkward names and muddled responsibilities
of the objects, and writing some code made those issues even clearer.

After some experimenting with the code and revising it (see commit log), I was able to "backfill" the CRC cards
for the original first use case to look something like this:

(not sure whether internals should be listed, decide before publishing, probably not)
(May want to note how we're NOT interacting with AR objects in controller / view)

> ExamUploader
>   R: Uploads zip file to S3
>   R: Generates random key on successful upload
>   R: Reports errors on upload failure
>
>   C: UploadStatus
>   (I): Submission
>   (I): TokenPhrase

> UploadStatus
>   R: Receives submission keyphrase on successful upload
>   R: Receives error messages on failed upload
>   R: Executes success/failure callbacks

(method level scope now... unsure how to build a CRC card for controllers, or whether we even should)
Unsure how to list implicit dependencies (UploadStatus is used, but it's a return value of ExamUploader)
 
> SubmissionController#create
>   R: Accepts uploaded files from HTTP request params
>   R: Redirects to status page on success, displays errors on upload form otherwise
>
>   C: ExamUploader
>   C*: UploadStatus

I feel like so far using cards has definitely been useful, but I also wondering
if I'm "doing it wrong"... I am struggling to decide what to put on cards and
what not to, and what level of detail/fidelity.

(Try to track down more examples / use cases for CRC)

---

SCENARIO: Check status of submission

Because this is a simple view of some raw data in the database, I decided to start off
with out any domain objects and stick to plain Rails conventions. So my initial CRC
cards look like this:

>  SubmissionController#show
>
>    R: Looks up submission by keyphrase
>    R: Renders view w. status and notes if key matches
>    R: Renders a "submission not found" error if key does not match
>
>    C: Submission

>  Submission
>    
>    R: Handles persistence and retrieval of submission status and notes

We'll see how this holds up to implementation and future revisions to use cases...

First snag is that we need to make a revision to the first use case (exam upload),
which does not yet set an initial status for the submission.

This involves adding a new responsibility to ExamUploader: *Sets submission status
to 'submitted' on successful upload*, and makes it so that Submission is now
more explicitly a collaborator rather than an implementation detail.

I didn't bother to add a responsibility explicitly for adding a note explaining
the status because I'm unsure whether we'll keep that behavior or not, and it
seems like a minor detail.

The controller action ends up looking like this:

```ruby
class SubmissionsController < ApplicationController
  # FIXME: routing, and maybe a wrapper object like ExamStatus.fetch(code)
  def show
    @submission = Submission.find_by_code(params[:code])

    render "submissions/not_found" unless @submission.present?
  end
end
```

Because so far the only methods we need from `Submission` are attributes generated
by ActiveRecord, there isn't much of a need for a custom domain object yet.

NOTE:
Right now we're leaving submission status as a semi-arbitrary string, but this is what the real app will need:

  * submitted: files have been uploaded but not checked by a human yet
  * under review: files have been checked, and solution has been verified as correct
  * error: problem with uploaded files and/or incorrect solution (include a note w. explanation)
  * accepted: solution has been reviewed, passed the entrance exam, and was selected by the lottery
  * waitlist: solution that has been reviewed, passed the entrance exam, but was not selected by the lottery 
  * not accepted: solution has been reviewed and entrance exam was not passed (include a reason)

----


If after a certain date the accepted solutions have not been claimed, we will begin working through
the wait list and invite people from it.

-- Set status of submission

Need a password or some other way of authenticating as an admin to do this.

-- Download a solution

-- Cancel a submission
