load(Task.load("demo/load/demo_load_lv2::_mul"))
class Avg
  def self.call(array)
    array.sum.to_f / array.size
  end
end

def mul(a, b)
  _mul(a, b)
end