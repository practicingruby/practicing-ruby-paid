class StatisticalCollection
  def initialize(data)
    self.data = data
  end

  def sum
    data.reduce(:+) 
  end

  def average
    sum / data.count.to_f
  end 

  private

  attr_accessor :data
end

class StatisticalReport
  def initialize(filename)
    self.input = filename
    
    self.stats = StatisticalCollection.new(each)
  end

  def to_s
    "The sum is #{stats.sum}, and the average is #{stats.average}"
  end

  private 

  attr_accessor :input, :stats

  def each
    return to_enum(__method__) unless block_given?

    File.foreach(input) { |e| yield(e.chomp.to_i) }
  end
end

puts StatisticalReport.new("numbers.txt")
