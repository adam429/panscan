class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # def self.count
  #   key = "#{name.split("::")[-1]}-count"
  #   cache = Cache.get(key)
  #   if cache==nil then
  #     return Cache.set(key,super())
  #   else
  #     return cache
  #   end
  # end
end
