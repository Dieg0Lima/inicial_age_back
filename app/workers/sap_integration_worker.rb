class SapIntegrationWorker
  include Sidekiq::Worker

  def perform(limit = 10)
    begin
      integration_service = SapServices::SapIntegration.new
      integration_service.check_and_export_customers(limit)
    rescue StandardError => e
      puts "Erro ao executar SapIntegrationWorker: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end
