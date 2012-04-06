text = ARGF.read

text.gsub!(/(.*)=entry\s+/m,"")
text.gsub!('<pre name="code" class="ruby">', '```ruby')
text.gsub!('<pre>','```')
text.gsub!('</pre>','```')
text.gsub!('<tt>','`')
text.gsub!('</tt>','`')
text.gsub!('h3.','###')

text << %{
  
> **NOTE:** This article has also been published on the Ruby Best Practices blog. There [may be additional commentary](COMMENTARY_LINK_HERE) 
over there worth taking a look at.
}

puts text
