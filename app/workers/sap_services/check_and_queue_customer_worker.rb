module SapServices
  class CheckAndQueueCustomersWorker
    include Sidekiq::Worker

    def perform
      integration = SapIntegration.new
      integration.check_and_queue_customers
    end
  end
end
