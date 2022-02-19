Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  root "epoch#index"

  get "/console", to: "epoch#web_console"
  get "/log", to: "epoch#log"

  get "/stats", to: "epoch#stats"
  post "/stats/clean_cache", to: "epoch#stats_clean_cache"

  get "/epoch/all", to: "epoch#all"
  get "/epoch/:id", to: "epoch#epoch"

  get "/address/top", to: "epoch#address_top"
  get "/address/:id", to: "epoch#address"
  get "/address/group/top", to: "epoch#address_group_top"
  get "/address/group/:group", to: "epoch#address_group"
  get "/address/group/graph/:group", to: "epoch#address_group_graph"

  post "/address/tag/:id", to: "epoch#address_tag"

  get "/transfer/top_contract", to: "epoch#top_contract"
  get "/transfer/top_transfer", to: "epoch#top_transfer"
  get "/transfer/address/:id", to: "epoch#trans_addr"
  get "/transfer/:id", to: "epoch#transfer"

  get "task/worker", to: "task#worker"
  get "task/task", to: "task#task"
end
