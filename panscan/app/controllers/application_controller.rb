module LoginFilter
  USERS = {
    "team" => {
      auth: "Uniswap2022!@#",
      role: "team",
    },

    "panbot" => {
      auth: "Panbot2022!@#",
      role: "panbot",
      allow: "epoch/*",
      deny: "epoch/web_console,epoch/log,epoch/stats,epoch/stats_clean_cache"
    },
  }

  def cur_user_role
    @cur_user[:role] if @cur_user
  end

  def cur_user_name
    @cur_user[:username] if @cur_user
  end

  def access_filter()
    puts caller[0]
    puts cur_user_name
    # if access==true and action!=nil then
    #   puts caller[0]
    #   controller =  controller.class.to_s.underscore.split("_")[0]
    #   puts "#{controller}##{action}"
    #
    #   # redirect_to "/404"
    # end
  end

  def login_filter
    access = authenticate_or_request_with_http_basic do |username,password|
        @cur_user = USERS[username]
        if @cur_user then
          @cur_user[:username] = username
          auth = @cur_user[:auth]
        end

        password == auth
    end
  end
  #   access = authenticate_or_request_with_http_digest do |username|
  #     @cur_user = USERS[username]
  #     if @cur_user then
  #       @cur_user[:username] = username
  #       auth = @cur_user[:auth]
  #     else
  #       auth = nil
  #     end
  #     auth
  #   end
  # end
end

class ApplicationController < ActionController::Base
    include Pagy::Backend

    include LoginFilter

    before_action :login_filter, except: :task_return_view
end