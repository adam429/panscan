loop do
    dest_path = "./app/tasks/backup"
    names = Task.where("name is not null").where("tid is not null").where(" now() - save_timestamp < ? ","1 minutes").map {|x| x.name }.uniq

    names.each do |name|
        task = Task.where(name:name).where("tid is not null").order(save_timestamp: :desc).first
        File.write "#{dest_path}/#{name}.rb", task.code
    end

    puts `git add *`
    puts `git commit -m 'task backup'`
    puts `git push`

    puts "==time: #{time.now.to_s(:db)}=="
    sleep(60)
end