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
      get :place_recommendations, to: "place_recommendations#index"
    end
    resources :stops, only: [:create, :destroy]
    resources :checklist_items, only: [:create, :update, :destroy]
    resources :expenses, only: [:create, :destroy]
    resources :memberships, controller: "trip_memberships", only: [:create, :destroy]
    resources :comments, only: [:create, :edit, :update, :destroy]
  end
end
