Rails.application.routes.draw do
  get "trips/index"
  get "trips/new"
  get "trips/create"
  get "trips/show"
  get "trips/destroy"
  root "pages#home"

  get    "/signup", to: "users#new"
  post   "/signup", to: "users#create"

  get    "/login",  to: "sessions#new"
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  resources :trips, only: [:index, :new, :create, :show, :destroy]
end
