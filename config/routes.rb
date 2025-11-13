Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  # Skip everything except OmniAuth - we're OAuth-only (no email/password, no password resets)
  devise_for :users, skip: [ :registrations, :sessions, :passwords ],
             controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  # Custom sign out route (DELETE only, no sign in form)
  devise_scope :user do
    delete "users/sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "comparisons#index"

  # Comparison routes
  resources :comparisons, only: [ :create, :show ]

  # API routes (v1) - Conditional subdomain routing
  # Development:  localhost:3001/api/v1/comparisons
  # Production:   api.reporeconnoiter.com/v1/comparisons
  constraints(Rails.env.production? ? { subdomain: "api" } : {}) do
    scope path: (Rails.env.production? ? nil : "api"), module: "api" do
      namespace :v1, defaults: { format: :json } do
        # API root - shows available endpoints
        root to: "root#index"

        # Authentication endpoints
        post "auth/exchange", to: "auth#exchange"

        # Comparison endpoints
        resources :comparisons, only: [ :index, :show, :create ]
        get "comparisons/status/:session_id", to: "comparisons#status", as: :comparison_status

        # Repository endpoints
        resources :repositories, only: [ :index, :show ] do
          member do
            post :analyze
          end
        end
        get "repositories/status/:session_id", to: "repositories#status", as: :repository_status

        # Profile endpoint (requires user auth)
        get "profile", to: "profile#show"

        # Admin endpoints (requires admin role)
        namespace :admin do
          get "stats", to: "stats#index"
        end

        # OpenAPI documentation endpoints
        get "openapi.json", to: "docs#openapi_json", as: :openapi_json  # For Swagger UI
        get "openapi.yml", to: "docs#openapi_yaml", as: :openapi_yaml   # For AI/programmatic access
      end
    end
  end

  # Session exchange for Next.js → Rails seamless authentication
  # Allows JWT-authenticated users to access Rails-only UIs
  get "session_exchange", to: "session_exchange#create"

  # Profile page (requires authentication)
  get "profile", to: "profile#show"
  delete "profile", to: "profile#destroy"

  # Repository routes (requires authentication)
  resources :repositories, only: [ :index, :show ] do
    member do
      post :create_analysis
    end
  end

  # Admin routes (requires authentication + admin status)
  namespace :admin do
    get "stats", to: "stats#index"
    resources :users, only: [ :index, :create, :destroy ]

    # Mission Control for job monitoring
    authenticate :user do
      mount MissionControl::Jobs::Engine, at: "/jobs"
    end
  end
end
