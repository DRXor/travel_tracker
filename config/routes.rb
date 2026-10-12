Rails.application.routes.draw do
  root "pages#home"

  get "/ui-kit", to: "pages#ui_kit", as: :ui_kit

  get "/signup", to: "users#new"
  post "/signup", to: "users#create"

  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  resources :trips, only: [:index, :new, :create, :show, :destroy]
end
