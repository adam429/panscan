def chart_data2(input)
  arr = (1..input).map { |x,|
    x ** 2
  }
  spec = { title: "A simple pie chart", data: { values: [{ category: 1, value: arr.filter { |x,|
    0 <= x && x < 100
  }.sum }, { category: 2, value: arr.filter { |x,|
    100 <= x && x < 500
  }.sum }, { category: 3, value: arr.filter { |x,|
    500 <= x && x < 2000
  }.sum }, { category: 4, value: arr.filter { |x,|
    2000 <= x && x < 5000
  }.sum }, { category: 5, value: arr.filter { |x,|
    5000 <= x && x < 10000
  }.sum }] }, mark: "arc", encoding: { theta: { field: "value", type: "quantitative" }, color: { field: "category", type: "nominal" } } }
  return spec
end