Writing robust code is always challenging, even when dealing with extremely well controlled environments. But when you cross over into the danger zone where software failures can result in data loss or extended service interruptions, coding for robustness becomes essential even if it is inconvenient to do so. 

In this article, I will share some of the lessons I've learned about building stable software through my work on the [Newman mail framework](https://github.com/mendicant-university/newman). While the techniques I've discovered so far are fairly ordinary and obvious, it was easy to underestimate their importance in the early stages of the project's development. My hope is that by exposing my stumbling points, it will save others from making the same mistakes.

### Collect enough information about failures

In many contexts, it's easy to get as much information as you need to track down failures. When your environment is well controlled, a good stack trace combined with a few well placed `puts` statements are often all you need to start reproducing an error in your development environment. However, all of that goes out the window when you are developing framework code.

To get a clearer sense of the problem, consider that Newman's server software knows almost nothing about the applications it runs, nor does it know much of anything about the structures of the emails it is processing. It also cannot assume that its interactions with external IMAP and SMTP servers will be perfectly stable. In this kind of environment, something can go wrong at every possible turn. This means that it is necessary to put checkpoints at various points along the critical path so that when something fails, you can get an idea of where and why it failed. 



### Reduce the cost of analyzing failures 

### Plan for various kinds of predictable failures

### Limit the impact of catastrophic failures  

A few days before this article was published, I accidentally introduced an infinite send/receive loop into the experimental Newman-based mailing list system [MailWhale](https://github.com/mendicant-university/mail_whale). I caught the problem right away, but not before my email provider banned me for 1 hour for exceeding my send quota. In the few minutes of chaos before I figured out what was going wrong, there was a window of time in which any incoming emails would simply be dropped, resulting in data loss.

It's painful to imagine what would have happened if this failure occured while someone wasn't actively babysitting the server. While the process was crashing with a `Net::SMTPFatalError` each time cron ran it, this happened after reading all incoming mail. As a result, the incoming mail would go unanswered and get dropped from the incoming queue, effectively failing silently. Once the quota was lifted, a single email would cause the server to start thrashing again, eventually leading to a permanent ban. In addition to these problems, anyone using the mailing list would be bombarded with at least a few duplicate emails before the quota kicked in each time. Although I was fortunate to not live out this worst-case scenario, the thought of this happening was bone chilling.

While the infinite loop I introduced could probably be avoided by doing some simple checks in Newman, the problem of the server failing repeatedly is a general defect that could cause all sorts of different problems down the line. To solve this problem, I've implemented a simplified version of the circuit breaker design pattern in [MailWhale](http://en.wikipedia.org/wiki/Circuit_breaker_design_pattern), as shown below:

```ruby
require "fileutils"

# unimportant details omitted...

begin
  if File.exists?("server.lock")
    abort("Server is locked because of an unclean shutdown. Check "+
          "the logs to see what went wrong, and delete server.lock "+
          "if the problem has been resolved") 
  end

  server.tick
rescue Exception
  FileUtils.touch("server.lock")
  raise 
end
```

With this small change, any exception raised by the server will cause a lock file to be written out to disk, which will then be detected the next time the server runs. As long as the `server.lock` file is present, the server will immediately shut itself down rather than continuing on with its processing. This forces someone (or some other automated process) to intervene in order for the server to resume normal operations, which makes repeated failure a whole lot less likely. 

If this circuit breaker were in place when I triggered the original infinite loop, I would have still exceeded my quota, but the only data loss would be the first request the server failed to respond to. All email that was sent in the interim would remain in the inbox until the problem was fixed, and there would be no chance that the server would continue to thrash without someone noticing that an unclean shutdown had occurred. This is clearly a better behavior, and perhaps this is how things should have been implemented in the first place.

Of course, we now have the problem that this code is a bit too aggressive. There are likely to be many kinds of failures which are transient in nature, and shutting down the server and hard-locking it like this feels overkill for those scenarios. However, I am gradually learning that it is better to whitelist things than blacklist them when you can't easily enumerate what can possibly go wrong, and for that reason I've chosen to go with an extremely conservative solution. I'll know a lot better whether or not this was the right way to go after I've had the chance to put this technique through its paces a bit. 

### Do the best you can with subtle failures

### Reflections
