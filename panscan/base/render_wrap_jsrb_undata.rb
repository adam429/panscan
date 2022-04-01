def jsrb_undata(data)
  ret = data.map { |k, v|
    if v =~ /^\(MappingObject\)\|\|\|/
      (_, class_name, data) = v.split("|||")
      obj = (Object.const_get(class_name)).new
      obj.from_data(data)
      [k, obj]
    else
      [k, v]
    end
  }.to_h
end