__TASK_NAME__ = "demo/demo_formatter"

def main()
    return [1,2,3,4]
end

def render_html()
'''<h1>output</h1>
<% @raw_ret.each do |item| %>
    <li><%= item %></li>
<% end %>

<h1>counter</h1>
<div id="counter"></div>
'''
end

def render_js_rb()
'''
puts "hello world!"

counter = 0

$$[:setInterval].call(->{ $document.at_css("#counter").inner_html="tick #{counter}"; counter=counter+1 },1000)

'''
end

