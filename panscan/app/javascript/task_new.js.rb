def take_action(json)
    if json[:action] == "redirect" then
        $$.location.href = json[:to]
    end

    if json[:action] == "open" then
        url = json[:to]
        `window.open(url)`
    end
    
    if json[:action] == "message" then
        $document.at_css("#message").inner_html = " | Message: "+json[:message]
        $$[:setTimeout].call(->{ $document.at_css("#message").inner_html="" },5000)
        do_update_page
    end
end

def get_page
    tid = $document.at_css("#tid").inner_html
    status = $document.at_css("#status").inner_html
    code = Native(`editor.getValue()`)
    json = {status:status, tid:tid, code:code, params:get_params}
end

def do_update_page()
    json = get_page
    get_server_task(json[:tid]) do |task|
        update_page(task)
    end
end

def update_page(json)
    $document.at_css("#tid").inner_html = json[:tid]
    $document.at_css("#name").inner_html = json[:name]
    $document.at_css("#run_timestamp").inner_html = json[:run_timestamp]
    $document.at_css("#save_timestamp").inner_html = json[:save_timestamp]
    $document.at_css("#updated_at").inner_html = json[:updated_at]
    $document.at_css("#status").inner_html = json[:status]
    $document.at_css("#runner").inner_html = json[:runner]
    $document.at_css("#output").inner_html = json[:output]
    $document.at_css("#return").inner_html = json[:return]
end

def get_server_task(tid)
    Browser::HTTP.get "/task/json/#{tid}" do
        on :success do |res|
            yield(res.json)
        end        
    end
end



def update_task_run
    json = get_page
    if (json[:status]=="run" || json[:status]=="open") then
        get_server_task(json[:tid]) do |task|
            update_page(task)
            $$[:setTimeout].call(->{ update_task_run },1000)
        end
    end    
end

def do_run
    json = get_page
    
    if (json[:status]=="run" || json[:status]=="open") then
        take_action({action:"message",message:"task is waiting for run"})
    else
        json["return"] = ""
        json["runner"] = ""
        json["output"] = ""
        json["status"] = "open"
        update_page(json)
    
        Browser::HTTP.post "/task/run", json do
            on :success do |res|
                take_action(res.json)
                $$[:setTimeout].call(->{ update_task_run },1000)
            end        
        end
    end
end



    def myalert(value)
    `console.log(value)`

    value
  end

  def do_save

    Browser::HTTP.post "/task/save", get_page do
        on :success do |res|
            take_action(res.json)
        end        
    end
end

def do_fork
    Browser::HTTP.post "/task/fork", get_page do
        on :success do |res|
            take_action(res.json)
        end        
    end
end


def get_params
    ret = {}
    $params.each do |param| 
        ret[param] = $document.at_css("#"+param).value
    end
    return ret
end

def update_refs()
    json = get_page
    code = json[:code]

    refs1 = code.scan(/Task.load\(([\"\'a-zA-Z0-9\-_\/]+)\)/).flatten
    refs2 = code.scan(/Task.run_remote\(([\"\'a-zA-Z0-9\-_\/]+)/).flatten

    refs = (refs1 + refs2).uniq.filter {|x| ['"',"'"].include?(x[0]) and ['"',"'"].include?(x[-1])}.map {|x| x[1,x.size-2]}
    
    refs_html = refs.map { |ref|
        url,_ = ref.split("::")
        url = url.gsub(/\//,"%2F")
        "<li><a href='/task/#{url}'>#{ref}</a></li>"
    }.join("\n")

    $document.at_css("#refs").inner_html = refs_html

end


def update_params(init_params=nil)
    json = get_page
    param_json = json[:params]
    if init_params then
        param_json = init_params
    end

    code = json[:code]
    params = code.scan(/(__[a-zA-Z0-9_]+__)/).flatten
    params = params.filter {|x| x!='__TASK_NAME__'}.map {|x| x.gsub(/^__/,"").gsub(/__$/,"") }
    if params.size>0 then
        $document.at_css("#params_box").show
    else
        $document.at_css("#params_box").hide
    end
    if params!=$params then
        params_html = params.map { |param|
            "<tr><td>#{param}</td><td> = </td><td><input id='#{param}' type='text' name='#{param}' value='#{param_json[param]}' ></td></tr>"
        }.join("\n")
        params_html = "<table>#{params_html}</table>"

        $document.at_css("#params").inner_html = params_html
        $params = params
    end
end


$document.ready do    


    $params = {}
    $meta_down = false
    $shift_down = false

    $document.at_css("#save").on(:click) do
        do_save
    end

    $document.at_css("#run").on(:click) do
        do_run
    end

    $document.at_css("#fork").on(:click) do
        do_fork
    end

    ## init params from page div to input value
    init_params = $document.at_css("#init_params").inner_html


    json = get_page()
    update_params(JSON.parse(init_params=="" ? "{}" : init_params))
    update_task_run

    $$[:setInterval].call(->{ 
        update_params
        update_refs
    },1000)    

    $document.body.on (:keydown) do |e|
        $meta_down = true if e.meta?
        $shift_down = true if e.shift?
        if e.meta? and e.char=="S" then
            puts "save task"
            do_save
            e.prevent
        end
        if e.shift? and e.key=="Enter" then
            puts "run task"
            do_run
            e.prevent
        end
    end
    $document.body.on (:keyup) do |e|
        $meta_down = false if e.meta?
        $shift_down = false if e.shift?
    end

end
