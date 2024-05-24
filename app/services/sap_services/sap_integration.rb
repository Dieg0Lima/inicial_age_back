module SapServices
  class SapIntegration
    require "rest-client"
    require "dotenv/load"

    def customer_exists_in_sap?(customer)
      b1_url = ENV["B1_API_URL"]
      url = "#{b1_url}/BusinessPartners?$filter=U_ALF_CNPJ eq '#{customer.tx_id}'"
      begin
        response = RestClient.get(url, { accept: :json })
        result = JSON.parse(response.body)
        result["d"]["results"].any?
      rescue RestClient::NotFound
        false
      rescue RestClient::Exception => e
        puts "Erro ao verificar cliente no SAP: #{e}"
        false
      end
    end

    def check_and_queue_customers
      Customer.find_each do |customer|
        unless customer_exists_in_sap?(customer)
          ExportQueue.find_or_create_by(customer_id: customer.id) do |queue|
            queue.export_scheduled_at = Time.now.end_of_day + 1.second
          end
        end
      end
    end

    private

    def queue_customer_for_export(customer)
      next_midnight = Time.now.end_of_day + 1.second

      CustomerExportWorker.perform_at(next_midnight, customer.id)
      puts "Cliente #{customer.name} agendado para exportação à 00:00."
    end
  end
end
