# CORS Configuration
# Allows API access from different origins (e.g., Next.js frontend)
#
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Development: Allow all localhost origins (easier for dev)
    if Rails.env.development?
      origins "*"  # Allow all origins in development
    else
      # Production: Allow your Next.js domain
      # Set NEXTJS_DOMAIN env var to your frontend URL (e.g., "https://myapp.vercel.app")
      origins ENV.fetch("NEXTJS_DOMAIN", "https://reporeconnoiter.com").split(",").map(&:strip)
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
