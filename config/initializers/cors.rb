# CORS Configuration
# Allows API access from different origins (e.g., Next.js frontend)
#
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Development: Allow localhost on common Next.js/Vite ports
    if Rails.env.development?
      origins "http://localhost:3000",
              "http://localhost:3001",
              "http://localhost:4000",
              "http://localhost:5173",
              "http://127.0.0.1:3000",
              "http://127.0.0.1:3001"
    else
      # Production: Allow your Next.js domain
      # Set NEXTJS_DOMAIN env var to your frontend URL (e.g., "https://myapp.vercel.app")
      origins ENV.fetch("NEXTJS_DOMAIN", "http://localhost:3000")
    end

    # Allow all API routes
    resource "/api/*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: false,
      # Expose pagination headers if needed in future
      expose: [ "X-Total-Count", "X-Page", "X-Per-Page" ]

    # Allow documentation routes (Swagger UI)
    resource "/api-docs*",
      headers: :any,
      methods: [ :get, :options, :head ],
      credentials: false
  end
end
