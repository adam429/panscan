class MappingObject
  def self.add_class
    RenderWrap.load(Task.load("base/render_wrap::jsrb_undata"))
    RenderWrap.load(Task.load("base/render_wrap::MappingObject"))
    RenderWrap.load(Task.load("#{$task.name}::#{self.name}"))
  end

  def to_data
  end
end
