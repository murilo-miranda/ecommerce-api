require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  resources :products
  get "cart" => "carts#show"
  post "cart" => "carts#create"
  post "cart/add_item" => "carts#add_item"
  delete "cart/:product_id" => "carts#destroy"
  get "up" => "rails/health#show", as: :rails_health_check

  root "rails/health#show"
end
