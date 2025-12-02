Rails.application.routes.draw do
  resource :session, only: [ :new, :create, :destroy ]
  resources :password_resets, only: [ :new, :create, :edit, :update ], param: :token
  resource :contact, only: [ :create ]

  get "dashboard", to: "dashboard#index", as: :dashboard
  get "library", to: "library#index", as: :library
  get "library/:id/read", to: "library#read", as: :library_read
  get "terms", to: "pages#terms", as: :terms
  get "privacy", to: "pages#privacy", as: :privacy

  namespace :dashboard do
    resources :staff do
      member do
        patch :deactivate
        patch :activate
        patch :reset_password
      end
    end
    resources :documents
    resource :profile, only: [ :edit, :update ]
    get "metadata_suggestions", to: "metadata_suggestions#index"
  end

  constraints subdomain: /.+/ do
    get "admin(/*path)", to: redirect("/dashboard")
  end

  scope :admin, as: :admin do
    get "login", to: "admin/sessions#new"
    post "login", to: "admin/sessions#create"
    delete "logout", to: "admin/sessions#destroy"
  end

  ActiveAdmin.routes(self)

  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
