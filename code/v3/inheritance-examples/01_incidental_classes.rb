class EnumerableCollection
  def size
    count = 0
    each { |e| count += 1 }
    count
  end

  # Samnang's implementation from Issue 2.4
  def reduce(arg=nil) 
    return reduce {|s, e| s.send(arg, e)} if arg.is_a?(Symbol)

    result = arg
    each { |e| result = result ? yield(result, e) : e }

    result
  end
end

class StatisticalCollection < EnumerableCollection
  def sum
    reduce(:+) 
  end

  def average
    sum / size.to_f
  end 
end

class StatisticalReport < StatisticalCollection
  def initialize(filename)
    self.input = filename
  end

  def to_s
    "The sum is #{sum}, and the average is #{average}"
  end

  private 

  attr_accessor :input

  def each
    File.foreach(input) { |e| yield(e.chomp.to_i) }
  end
end

puts StatisticalReport.new("numbers.txt")
