require 'opal'
require 'native'
require 'promise'
require 'browser/setup/full'

$document.ready do    
    $document.at_css("#save").on(:click) do

        tid = $document.at_css("#tid").inner_html
        code = Native(`editor.getValue()`)

        json = {tid:tid,code:code}

        Browser::HTTP.post "/task/save",json do
            on :success do |res|
                alert res.json.inspect
            end        
        end

    end
end