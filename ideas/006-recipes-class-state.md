## Problem

*I want to access some objects (or data) from anywhere in my code, but I'm 
not sure how to model it cleanly*

This is commonly seen in cases where you have some configuration data you want
to share between objects without explicitly passing it into every object you
create. For example:

```ruby
  message = MyMail::Message.new(:message => "Hello World", 
                                :to      => "test@test.com")
  message.deliver
```

## Solution

*First think through whether there is a clean way to model your
code without relying on global data. If you can't come up with
a better design, use module (or class) accessors to set default 
values wherever shared state is needed, but avoid hardcoded 
references to global state.*


```ruby
  MyMail.smtp_settings = { :address  => "smtp.example.com",
                           :username => "example@example.com",
                           :password => "mypass" }
```

```ruby
module MyMail
  class << self
    attr_accessor :smtp_settings
  end
end
```

```ruby
module MyMail
  class Message
    # ...

    def deliver(settings = MyMail.smtp_settings)
      # ...
    end
  end
end
```

## Discussion

- class variables vs. class instance variables (and what `class << self` does)
- global state should be used as a default, not hard coded 
- Impacts on testing / reliability / etc
