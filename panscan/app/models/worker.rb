
require 'open3'

class Worker
    def initialize
        create_pem_file
    end

    def get_public_ips
        get_public_ip_str = "aws lightsail get-instances --no-cli-pager --region 'us-east-1' --query 'instances[].{name:name,publicIpAddress:publicIpAddress}'"
        data = `#{get_public_ip_str}`
        @public_ips = JSON.parse(data).map {|x| [x["name"],x["publicIpAddress"]]}.to_h
    end

    def get_instances
        get_public_ips

        @public_ips.filter {|x| x=~/^panworker-/}.to_a.sort {|x,y| x[0]<=>y[0]}.to_h
    end

    def get_workers
        ret = get_instances
        ret = Parallel.map(ret,in_threads: 10) {|k,v|
            ip = v
            docker_ret = run_cmd(ip,"docker ps")
            docker = []
            
            if docker_ret == "(timeout)" then
                docker = "(timeout)"
            elsif docker_ret != "" then
                docker_ps = docker_ret.split("\n")
                docker_ps = docker_ps[1,docker_ps.size-1]
                docker = docker_ps.map {|x| {worker:x.split(" ")[-1],run_time:(x.scan(/ Up ([ 0-9a-zA-Z]+) panworker/)).first.first,ps:x} }
            end
            
            new_v = {ip:ip, docker:docker}
            [k,new_v]
        }
    end

    def delete_worker(worker)
        get_public_ips

        instance, docker = worker.split("_")

        Task.where(status:"run").where(runner:worker).map do |t|
            t.status = "kill"
            t.save
        end

        stop_script = """docker stop #{worker}
        docker rm #{worker}"""

        worker_run_script([instance],stop_script)
    end

    def start_worker(instance)
        get_public_ips
        start_script = '''docker container run -d --restart=always -e DB_CONNECT_STR=__PARAMS_CONNECT_STR__ -e WORKER_NAME="__WORKER__" --name __WORKER__  adam429/pan-repo:panworker'''
        script_a = start_script.gsub(/__WORKER__/,"#{instance}_#{SecureRandom.hex(2)}").gsub(/__PARAMS_CONNECT_STR__/,ENV["DB_CONNECT_STR"])

        worker_run([instance],script_a)
    end

    def create_instances(instance_number, docker_per_instance=6)
        # generate instance number list
        instances = get_instances.map {|k,v| k}
        last_id = 0
        if not instances.size == 0 then
            _, last_id = instances.last.split("-")
        end
        last_id = last_id.to_i
        worker = (last_id+1..last_id+instance_number).map {|x| "panworker-#{x}"}
        
        start_ec2(worker,docker_per_instance)
    end

    def delete_instances(instances)
        Parallel.map(instances,in_threads: 10) { |w| 

        Task.where(status:"run").where("runner like ?","#{w}%").map do |t|
            t.status = "kill"
            t.save
        end

        delete_worker = "aws lightsail delete-instance --no-cli-pager --instance-name #{w}" 
        puts delete_worker
        system(delete_worker)
      }
    end

    def delete_all_instances()
        delete_instances(get_instances.map {|k,v| k})
    end

    def restart_worker(workers)
        get_public_ips
        workers.each do |worker|
            instance, docker = worker.split("_")
        
            if docker!=nil then
                cmd = "docker restart #{worker}"          
                worker_run([instance],cmd)

                Task.where(status:"run").where(runner:worker).map do |t|
                    t.status = "kill"
                    t.save
                end    
            else
                cmd = "docker restart $(docker ps -a -q)"          
                worker_run([instance],cmd)

                Task.where(status:"run").where("runner like ?","#{instance}%").map do |t|
                    t.status = "kill"
                    t.save
                end
    
            end
        end

    end


    def run_cmd(ip,cmd)
        puts "====begin cmd #{time=Time.now} @#{ip}===="
        cmd = "timeout -v 300 ssh -i aws.pem -o 'StrictHostKeyChecking no' ubuntu@#{ip} '#{cmd}'"
        puts "#{cmd}"

        stdout, stderr, status = Open3.capture3(cmd)
        ret = stdout

        ret = "(timeout)" if stderr=~/timeout: sending signal/
        puts ret

        puts "====end cmd #{Time.now} @#{ip} time #{Time.now-time} s===="
        return ret
      end
      
      
    def worker_run(worker,cmd)
        puts "====worker_run begin cmd #{time=Time.now}===="
        ret = Parallel.map(worker,in_threads: 10) { |w| run_cmd(@public_ips[w],cmd) }
        puts "====worker_run end cmd #{Time.now} time #{Time.now-time} s===="
        return ret
    end
    
    def worker_run_script(worker,script)
        ret = nil
        cmd = script.split("\n")
        cmd.map {|c|
            ret = worker_run(worker,c)
        }
        return ret
    end

    private

    def create_pem_file
        return if File.file?("aws.pem")
        File.write "aws.pem", Vault.get("aws_pem_file")
        FileUtils.chmod 0400, 'aws.pem'
    end

    def start_ec2(worker,docker_per_instance)
        ## start ec2
        if worker.size>1 then
            create_worker = "aws lightsail create-instances --no-cli-pager --instance-names {#{worker.map{|x| "'#{x}'"}.join(',')}} --availability-zone 'us-east-1a' --blueprint-id 'ubuntu_20_04' --bundle-id 'large_2_0'"
        else
            create_worker = "aws lightsail create-instances --no-cli-pager --instance-names #{worker.map{|x| "'#{x}'"}.join(',')} --availability-zone 'us-east-1a' --blueprint-id 'ubuntu_20_04' --bundle-id 'large_2_0'"
        end
        puts create_worker
        system(create_worker)

        public_ips = get_public_ips

        ## install docker
        script1 = '''sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker $USER'''

        script2 = "newgrp docker"

        script3 = """sudo systemctl enable docker.service
        sudo systemctl enable containerd.service"""

        worker_run_script(worker,script1)

        Parallel.map(worker,in_threads: 10) { |w| 
            ip = public_ips[w]
            cmd = "ssh -i aws.pem -o 'StrictHostKeyChecking no' ubuntu@#{ip} '#{script2}'<<EOF\nexit\nEOF\n"
            puts cmd
            system(cmd)
        }

        worker_run_script(worker,script3)
        
        check = worker_run_script(worker,"docker run hello-world")
        check.each_with_index do |c,i|
            if not c =~ /Hello from Docker!/ then
                delete_instances([worker[i]])
                start_ec2([worker[i]],docker_per_instance)
            end
        end

        ## start dockers
        stop_script = """docker stop $(docker ps -a -q)
        docker rm $(docker ps -a -q)"""

        start_script = '''docker container run -d --restart=always -e DB_CONNECT_STR=__PARAMS_CONNECT_STR__ -e WORKER_NAME="__WORKER__" --name __WORKER__  adam429/pan-repo:panworker'''

        worker_run_script(worker,stop_script)

        output = Parallel.map(worker,in_threads: 10) { |w| 

            script_a = start_script.gsub(/__WORKER__/,"#{w}_#{SecureRandom.hex(2)}").gsub(/__PARAMS_CONNECT_STR__/,ENV["DB_CONNECT_STR"])
            worker_run_script([w],script_a)

            Parallel.map((2..docker_per_instance).to_a, in_threads: 10) { |i|
                script_a = start_script.gsub(/__WORKER__/,"#{w}_#{SecureRandom.hex(2)}").gsub(/__PARAMS_CONNECT_STR__/,ENV["DB_CONNECT_STR"])
                worker_run_script([w],script_a)
            }
        }
        return

    end
end
