class CustomerExportWorker
  include Sidekiq::Worker

  def perform
    ExportQueue.where("export_scheduled_at <= ?", Time.current).find_each do |queue|
      customer = Customer.find(queue.customer_id)
      SapServices::SapIntegration.new.export_customer_to_sap(customer)
      queue.destroy
    end
  end
end
