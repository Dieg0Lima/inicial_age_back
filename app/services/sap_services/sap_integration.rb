module SapServices
  class SapIntegration
    def initialize
      @username = ENV["B1_USERNAME"]
      @password = ENV["B1_PASSWORD"]
      @company_db = ENV["B1_COMPANYDB"]
    end

    def customer_exists_in_sap?(tx_id)
      authenticate_with_b1_slayer
      b1_url = ENV["B1_API_URL"]
      uri = URI("#{b1_url}/BusinessPartners?$filter=U_ALF_CNPJ eq '#{tx_id}'")

      request = Net::HTTP::Get.new(uri, { "Accept" => "application/json", "Cookie" => @b1_cookies })
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        result = JSON.parse(response.body)
        found = result["value"].any?
        puts "Cliente #{tx_id} #{found ? 'encontrado' : 'não encontrado'} no SAP."
        found
      else
        puts "Erro ao verificar cliente no SAP: #{response.message}"
        false
      end
    rescue StandardError => e
      puts "Erro ao verificar cliente no SAP: #{e.message}"
      false
    end

    def check_and_export_customers(limit = 5)
      authenticate_with_b1_slayer
      customers_processed = 0

      Person.where(client: true).find_each do |person|
        tx_id = person.tx_id
        next unless tx_id

        if customer_exists_in_sap?(tx_id)
          puts "Cliente #{tx_id} já encontrado no SAP. Verificando notas fiscais..."
          export_customer_invoices(person)
        else
          if all_invoices_exported?(person)
            puts "Todas as notas fiscais do cliente #{person.name} já foram exportadas. Não é necessário exportar o cliente."
          else
            begin
              data = customer_data_for_export(person)
              puts "JSON enviado para o SAP: #{data.to_json}"
              response = B1SlayerIntegration.create_business_partner(data, @b1_cookies)
              if response.is_a?(Hash) && response[:error]
                puts "Erro ao exportar cliente #{person.name} ao SAP: #{response[:error]}"
                puts "Detalhes do erro: #{response[:body]}"
              else
                puts "Cliente #{person.name} exportado com sucesso ao SAP."
                export_customer_invoices(person)
              end
            rescue StandardError => e
              puts "Erro ao exportar cliente #{person.name}: #{e.message}"
            end
          end
          customers_processed += 1
          break if customers_processed >= limit
        end
      end

      puts "Nenhum cliente novo para exportar." if customers_processed == 0
    end

    private

    def authenticate_with_b1_slayer
      response = B1SlayerIntegration.authenticate(@username, @password, @company_db)
      if response[:error]
        raise "Erro na autenticação com B1: #{response[:error]}"
      else
        @b1_cookies = B1SlayerIntegration.parse_cookies(response[:cookies])
      end
    end

    def customer_data_for_export(person)
      contract = Contract.find_by(client_id: person.id)
      raise "Contrato não encontrado para a pessoa com ID #{person.id}" if contract.nil?

      address = PeopleAddress.find(contract.people_address_id)

      {
        CardCode: next_card_code,
        CardName: person.name,
        AliasName: person.name_2,
        CardType: "C",
        GroupCode: "101",
        Series: -1,
        EmailAddress: person.email,
        FederalTaxID: person.tx_id,
        U_ALF_CNPJ: person.tx_id,
        Frozen: "tNO",
        Phone1: person.cell_phone_1,
        BPAddresses: [
          {
            AddressName: "Endereço de Cobrança",
            AddressType: "bo_BillTo",
            Street: address.street,
            Block: address.neighborhood,
            ZipCode: address.postal_code,
            City: address.city,
            County: "",
            Country: person.country,
            State: person.state,
            StreetNo: address.number
          },
          {
            AddressName: "Endereço de Entrega",
            AddressType: "bo_ShipTo",
            Street: address.street,
            Block: address.neighborhood,
            ZipCode: address.postal_code,
            City: address.city,
            County: "",
            Country: person.country,
            State: person.state,
            StreetNo: address.number
          }
        ],
        BPFiscalTaxIDCollection: [
          {
            Address: "",
            TaxId0: person.tx_id,
            TaxId1: ""
          }
        ]
      }
    end

    def next_card_code
      authenticate_with_b1_slayer
      b1_url = ENV["B1_API_URL"]
      uri = URI("#{b1_url}/BusinessPartners?$orderby=CardCode desc&$top=1")

      request = Net::HTTP::Get.new(uri, { "Accept" => "application/json", "Cookie" => @b1_cookies })
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        result = JSON.parse(response.body)
        last_card_code = result["value"].first["CardCode"]
        new_card_code = increment_card_code(last_card_code)
        puts "Último CardCode: #{last_card_code}, Próximo CardCode: #{new_card_code}"
        new_card_code
      else
        raise "Erro ao obter o último CardCode: #{response.message}"
      end
    rescue StandardError => e
      puts "Erro ao obter o último CardCode: #{e.message}"
      raise
    end

    def increment_card_code(last_card_code)
      last_code_number = last_card_code.gsub(/[^\d]/, '').to_i
      next_code_number = last_code_number + 1
      "J%04d" % next_code_number
    end

    def export_customer_invoices(person)
      invoices = Invoice.where(person_id: person.id, exported: false)
      invoices.each do |invoice|
        data = invoice_data_for_export(invoice)
        puts "JSON da fatura enviado para o SAP: #{data.to_json}"
        response = B1SlayerIntegration.create_invoice(data, @b1_cookies)
        if response.is_a?(Hash) && response[:error]
          puts "Erro ao exportar fatura #{invoice.id} ao SAP: #{response[:error]}"
          puts "Detalhes do erro: #{response[:body]}"
        else
          puts "Fatura #{invoice.id} exportada com sucesso ao SAP."
          invoice.update(exported: true)
        end
      end
    end

    def invoice_data_for_export(invoice)
      {
        CardCode: invoice.card_code,
        DocDate: invoice.doc_date.strftime("%Y-%m-%d"),
        DocDueDate: invoice.doc_due_date.strftime("%Y-%m-%d"),
        DocumentLines: invoice.line_items.map do |item|
          {
            ItemCode: item.item_code,
            Quantity: item.quantity,
            UnitPrice: item.unit_price,
            TaxCode: item.tax_code
          }
        end
      }
    end

    def all_invoices_exported?(person)
      Invoice.where(person_id: person.id, exported: false).count.zero?
    end
  end
end
