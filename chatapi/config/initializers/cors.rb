# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if Rails.env.production?
      origins "https://#{ENV.fetch('RENDER_API_HOST', nil)}",
              "https://#{ENV.fetch('RENDER_WEB_HOST', nil)}"
    else
      origins "http://localhost:3000",
              "http://localhost:3001"
    end

    resource "*",
      credentials: true,
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
