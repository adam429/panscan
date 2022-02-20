require 'reduce'
require 'opal'
require 'opal-browser'

source_path = "./app/javascript/"
dest_path = "./app/assets/javascript/"
files = ["task_new.js"]

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

        if dest_time-source_time < 1 then
            puts "source #{file} changed | source_time #{source_time} dest_time #{dest_time}"
            builder = Opal::Builder.new
            builder.build_str(open(source_file).read, '(inline)')
            File.write dest_file, builder.to_s           
            # reduced_data = Reduce.reduce(dest_file)
            # File.write dest_file, reduced_data
        end
    end
    sleep(1)
end