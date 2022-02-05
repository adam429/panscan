Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  get "/console", to: "epoch#web_console"
  get "/stats", to: "epoch#stats"
  get "/epoch/all", to: "epoch#all"
  get "/epoch/:id", to: "epoch#epoch"
  get "/address/:id", to: "epoch#address"
  get "/transfer/address/:id", to: "epoch#trans_addr"
  get "/transfer/:id", to: "epoch#transfer"
  get "/log", to: "epoch#log"
end
