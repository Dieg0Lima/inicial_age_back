Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*' # Permitir todas as origens em ambiente de desenvolvimento. Configure as origens reais em produção.
    resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
