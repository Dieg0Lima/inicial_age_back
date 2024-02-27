Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://192.168.69.80:8080' # ou '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options, :head], credentials: true
  end
end
