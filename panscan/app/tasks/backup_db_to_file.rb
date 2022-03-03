
def save_to_github
    puts `git add *`
    puts `git commit -m 'task backup'`
    puts `git push`
end

save_to_github()

loop do
    dest_path = "./app/tasks/backup"
    names = Task.where("name is not null").where("tid is not null").where(" now() - save_timestamp < ? ","1 minutes").map {|x| x.name }.uniq

    names.each do |name|
        task = Task.where(name:name).where("tid is not null").order(save_timestamp: :desc).first

        filename = "#{dest_path}/#{name}.rb"
        dirname = File.dirname(filename)
        unless File.directory?(dirname)
          FileUtils.mkdir_p(dirname)
        end
  
        File.write filename, task.code
    end

    save_to_github()
    puts "==time: #{Time.now.to_fs(:db)}=="
    sleep(60)
end