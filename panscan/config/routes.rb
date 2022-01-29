Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  get "/stats", to: "epoch#stats"
  get "/epoch/all", to: "epoch#all"
  get "/epoch/:id", to: "epoch#epoch"
  get "/address/:id", to: "epoch#address"
end
