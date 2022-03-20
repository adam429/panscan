
def save_to_github
    puts `git add *`
    puts `git commit -m 'task backup'`
    puts `git push`
end

def db_to_local_file(save_time = "1 minutes")
    dest_path = "./app/tasks/backup"
    names = Task.where("name is not null").where("tid is not null").where(" now() - save_timestamp < ? ",save_time).map {|x| x.name }.uniq

    names.each do |name|
        task = Task.where(name:name).where("tid is not null").order(save_timestamp: :desc).first

        filename = "#{dest_path}/#{name}.rb"
        dirname = File.dirname(filename)
        unless File.directory?(dirname)
          FileUtils.mkdir_p(dirname)
        end
  
        File.write filename, task.code
    end
end



db_to_local_file(save_time = "1 years")
save_to_github()

loop do
    db_to_local_file()
    save_to_github()
    puts "==time: #{Time.now.to_fs(:db)}=="
    sleep(60)
end