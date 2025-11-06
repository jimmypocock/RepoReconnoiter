Rails.application.routes.draw do
  # Devise routes for users
  # Skip everything except OmniAuth - we're OAuth-only (no email/password, no password resets)
  devise_for :users, skip: [ :registrations, :sessions, :passwords ],
    controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  # Custom sign out route (DELETE only, no sign in form)
  devise_scope :user do
    delete "users/sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "comparisons#index"

  # Comparison routes (no index - root serves that purpose)
  resources :comparisons, only: [ :create, :show ]

  # Mission Control for job monitoring (requires authentication)
  authenticate :user do
    mount MissionControl::Jobs::Engine, at: "/jobs"
  end
end
