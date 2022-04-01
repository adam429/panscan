def chart_data1(input)
  arr = (1..input).map { |x,|
    x ** 2
  }
  spec = { title: "A Simple Bar Chart", width: 200, height: 200, data: { values: [] }, mark: "bar", encoding: { x: { field: "a", type: "ordinal" }, y: { field: "b", type: "quantitative" } } }
  spec.[]("data").[]=("values", arr.map.with_index { |x, i|
    { a: i, b: x }
  })
  return spec
end