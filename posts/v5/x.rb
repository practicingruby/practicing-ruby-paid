def sort(xs)
  return xs if xs.length <= 1

  pivot = xs[xs.length / 2]

  sort(xs.select { |x| pivot > x}) + 
  xs.select { |x| pivot == x } +
  sort(xs.select { |x| pivot < x })
end

p sort([5,2,10,13,3,3,3,3,4,6,9,1])
