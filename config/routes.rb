Rails.application.routes.draw do
  root "pages#home"

  get "/ui-kit", to: "pages#ui_kit", as: :ui_kit

  get "/signup", to: "users#new"
  post "/signup", to: "users#create"

  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

    resources :trips do
    member do
      patch :plan
      patch :complete
      patch :cancel
      patch :restore
    end
    resources :stops, only: [:create, :destroy]
    resources :checklist_items, only: [:create, :update, :destroy]
  end
end
