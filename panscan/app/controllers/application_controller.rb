class ApplicationController < ActionController::Base
    include Pagy::Backend

    http_basic_authenticate_with name: "panbot", password: "Panbot2022!@#"
end
