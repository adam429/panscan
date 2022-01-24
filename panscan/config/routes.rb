Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  get "/epoch/foo", to: "epoch#foo"
  get "/epoch/:id", to: "epoch#epoch"
  get "/address/:id", to: "epoch#address"
end
