__TASK_NAME__ = "base_database"

def database_init(readonly=true)
    require 'active_record'
    require 'faraday'
    
    ActiveRecord::Base.establish_connection(ENV["DB_CONNECT_STR"])
    
    def run_code(code,model)
      open("#{model}.rb","w") {|f| f.write(code) }
      load "./#{model}.rb"
    end
    
    models = ["application_record","address","cache","vault","block","epoch","epoch_detail","event","transfer","log","tx"]
    models.each do |model| 
      url = "https://raw.githubusercontent.com/adam429/panscan/main/panscan/app/models/#{model}.rb"
      body = Faraday.get(url).body
      run_code(body,model)
    end

    code = """
      class ApplicationRecord < ActiveRecord::Base
        def delete
          raise ActiveRecord::ReadOnlyRecord
        end
        before_create { raise ActiveRecord::ReadOnlyRecord }
        before_destroy { raise ActiveRecord::ReadOnlyRecord }
        before_save {
          if self.class==Address and self.changed_attributes.filter {|k,v| k!='tag'}=={} then
          else 
            raise ActiveRecord::ReadOnlyRecord 
          end
        }
      end
    """
    run_code(code,"readonly") if readonly
end

def main
    database_init
    
    Epoch.count
end