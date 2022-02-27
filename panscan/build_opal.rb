require 'opal'
require 'opal-browser'
require 'opal/optimizer/sprockets'

source_path = "./app/javascript/"
dest_path = "./app/assets/javascript/"
files = ["task_new.js","opal_lib.js"]

loop do
    files.each do |file|
        source_file = "#{source_path}#{file}.rb"
        dest_file = "#{dest_path}#{file}"

        source_time = File.ctime(source_file) 
        dest_time = 0
        begin
            dest_time = File.ctime(dest_file) 
        rescue
            dest_time = source_time - 9999
        end

        if dest_time-source_time < 0.01 then
            puts "source #{file} changed | source_time #{source_time} dest_time #{dest_time}"
            begin
                builder = Opal::Builder.new.build(source_file)

                File.write dest_file,  "#{builder.to_s}\n//# sourceMappingURL=#{file}.map"
                File.write dest_file+".map", JSON.dump(builder.source_map.to_h)
            rescue  ScriptError, StandardError => error
                puts "Exception Class: #{ error.class.name }\n"
                puts "Exception Message: #{ error.message }\n"
                puts "Exception Backtrace:\n#{ error.backtrace.join("\n") }\n"
                File.write dest_file, "error build"           
            end
        end
    end
    sleep(1)
end