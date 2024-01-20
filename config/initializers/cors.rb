Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost', '127.0.0.1', '192.168.1.0'
    resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
  end
end