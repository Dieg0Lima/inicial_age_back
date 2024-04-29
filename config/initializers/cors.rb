Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:8080', '192.168.69.80:6969', 'localhost:3000', '192.168.1.30:6969', '192.168.72.194:6969'
    resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
