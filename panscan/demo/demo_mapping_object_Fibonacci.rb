class Fibonacci < MappingObject
  attr_accessor(:n)

  def to_data
    self.n
  end

  def from_data(data)
    self.n=data.to_i
  end

  def fn(n)
    if n == 0
      return 1
    end
    if n == 1
      return 1
    end
    return fn(n - 1) + fn(n - 2)
  end

  def result
    fn(self.n)
  end

  def initialize(n)
    self.n=n
  end
end
