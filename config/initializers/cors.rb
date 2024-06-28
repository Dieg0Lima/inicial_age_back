Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '192.168.69.79:3000', '192.168.69.79:6969', 'localhost:3000', '192.168.1.30:6969', '192.168.68.173:6969'
    resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
