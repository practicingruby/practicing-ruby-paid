## TODO MAKE APP AS EASY TO INSTALL AS POSSIBLE, WITH ALL INSTRUCTIONS
## NEEDED TO GET RUNNING ON HEROKU.


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

Other top-level use cases:

-- Check status of submission

  * submitted: files have been uploaded but not checked by a human yet
  * under review: files have been checked, and solution has been verified as correct
  * error: problem with uploaded files and/or incorrect solution (include a note w. explanation)
  * accepted: solution has been reviewed, passed the entrance exam, and was selected by the lottery
  * waitlist: solution that has been reviewed, passed the entrance exam, but was not selected by the lottery 
  * not accepted: solution has been reviewed and entrance exam was not passed (include a reason)

If after a certain date the accepted solutions have not been claimed, we will begin working through
the wait list and invite people from it.

-- Set status of submission

Need a password or some other way of authenticating as an admin to do this.

-- Download a solution

-- Cancel a submission
