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
        if result["value"].any?
          card_code = result["value"].first["CardCode"]
          puts "Cliente #{tx_id} encontrado no SAP com CardCode #{card_code}."
          card_code
        else
          puts "Cliente #{tx_id} não encontrado no SAP."
          nil
        end
      else
        puts "Erro ao verificar cliente no SAP: #{response.message}"
        nil
      end
    rescue StandardError => e
      puts "Erro ao verificar cliente no SAP: #{e.message}"
      nil
    end

    def check_and_export_customers(limit = 5)
      authenticate_with_b1_slayer
      customers_processed = 0

      Person.where(client: true).find_each do |person|
        tx_id = person.tx_id
        next unless tx_id

        card_code = customer_exists_in_sap?(tx_id)
        if card_code
          puts "Cliente #{tx_id} já encontrado no SAP. Verificando notas fiscais..."
          unless invoices_exported_to_sap?(card_code, tx_id)
            export_customer_invoices(person, card_code)
          end
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
              card_code = response["CardCode"]
              export_customer_invoices(person, card_code)
            end
          rescue StandardError => e
            puts "Erro ao exportar cliente #{person.name}: #{e.message}"
          end
        end
        customers_processed += 1
        break if customers_processed >= limit
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
        CardName: person.name,
        AliasName: person.name_2,
        CardType: "C",
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

    def export_customer_invoices(person, card_code)
      invoices = fetch_pending_invoices(person.tx_id)
      invoices.each do |invoice|
        data = invoice_data_for_export(invoice, card_code)
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

    def invoice_data_for_export(invoice, card_code)
      document_lines = invoice.invoice_note_items.map do |item|
        item_code, sequence_model, usage = map_item_code(item.description)
        {
          ItemCode: item_code,
          Quantity: 1,
          Price: item.total_amount,
          Usage: usage
        }
      end

      {
        invoice: {
          BPL_IDAssignedToInvoice: 2,
          CardCode: card_code,
          DocDate: invoice.issue_date.strftime("%Y-%m-%d"),
          DocDueDate: invoice.issue_date.strftime("%Y-%m-%d"),
          DocTotal: invoice.invoice_note_items.sum(&:total_amount),
          Incoterms: "9",
          SequenceCode: "-1",
          SequenceSerial: invoice.document_number,
          SequenceModel: document_lines.first[:SequenceModel],
          SeriesString: "1",
          DocumentLines: document_lines
        }
      }
    end

    def map_item_code(description)
      case description
      when 'TI1 - Manutenção e Serviços de Informática',
           'TI1 - Manutenção e outros Serviços de Informática - CNPJ: 40.085.602/0001-03',
           'TI1 - Manutenção e outros Serviços de Informática - CNPJ: 40.085.602/0001-03.',
           'TI1 - Manutenção e outros Serviços de Informática - CNPJ: 40.085.602/0001-03 (condomínio)',
           'TI1 - Manutenção e outros Serviços de Informática - CNPJ: 40.085.602/0001-03 (valor)',
           'TI1 - Manutenção e Serviços de Informática',
           'TI1 - Suporte Técnico, Manutenção e outros Serviços em Tecnologia da Informação'
        ['Venda01', '18', '18']
      when 'TI2 - Suporte Técnico',
           'TI2 - Suporte Técnico - CNPJ 40.085.642/0001-55',
           'TI2 - Suporte Técnico - CNPJ 40.085.642/0001-55.',
           'TI2 - Suporte Técnico - CNPJ 40.085.642/0001-55 (condomínio)',
           'TI2 - Suporte Técnico - CNPJ 40.085.642/0001-55 (valor)',
           'TI2 - Suporte Técnico, Manutenção e outros Serviços em Tecnologia da Informação' 
        ['Venda05', '46', '22']
      when 'Aluguel de Equipamento - SVA',
           'Aluguel de Equipamento - SVA - CNPJ: 40.120.934/0001-81',
           'Aluguel de Equipamento - SVA - CNPJ: 40.120.934/0001-81 ( Boleto )',
           'Aluguel de Equipamento - SVA - CNPJ: 40.120.934/0001-81 ( Colaborador )',
           'Aluguel de Equipamento - SVA - CNPJ: 40.120.934/0001-81 ( condomínio )',
           'Aluguel de Equipamento - SVA - CNPJ: 40.120.934/0001-81 ( condomínio ))',
           'Aluguel de Equipamento - SVA - CNPJ: 40.120.934/0001-81 ( débito automático)',
           'Aluguel de Equipamento - SVA - CNPJ: 40.120.934/0001-81 (valor)'
        ['Venda03', '20', '20']
      when 'SCI – Conexão de Internet',
           'SCI – Conexão de Internet - R$ 15,20',
           'SCI – Conexão de Internet - R$ 25,20',
           'SCI – Conexão de Internet - R$ 5,20',
           'SCI – Conexão de Internet - R$ 55,20',
           'SCI – Conexão de Internet - R$ 65,20',
           'Serviço de Conexão à Internet - SCI',
           'Serviço de Conexão à Internet - SCI - CNPJ: 40.086.752/0001-31',
           'Serviço de Conexão à Internet - SCI - CNPJ: 40.086.752/0001-31 (15,60)',
           'Serviço de Conexão à Internet - SCI - CNPJ: 40.086.752/0001-31 (15,69)',
           'Serviço de Conexão à Internet - SCI - CNPJ: 40.086.752/0001-31 (25,60)',
           'Serviço de Conexão à Internet - SCI - CNPJ: 40.086.752/0001-31 (2,75)',
           'Serviço de Conexão à Internet - SCI - CNPJ: 40.086.752/0001-31 (45,60)',
           'Serviço de Conexão à Internet - SCI - CNPJ: 40.086.752/0001-31 (4,70)',
           'Serviço de Conexão à Internet - SCI - CNPJ: 40.086.752/0001-31 (5,60)',
           'Serviço de Conexão à Internet - SCI - CNPJ: 40.086.752/0001-31 (59,20)',
           'Serviço de Conexão à Internet - SCI - CNPJ: 40.086.752/0001-31 (75,60)',
           'Serviço de Conexão à Internet - SCI - CNPJ: 40.086.752/0001-31 (condomínio).',
           'Serviço de Conexão à Internet - SCI - CNPJ: 40.086.752/0001-31 (Emp 2.5)'
        ['Venda04', '21', '21']
      else
        ['ItemPadrão', '1', '1']
      end
    end

    def invoices_exported_to_sap?(card_code, tx_id)
      authenticate_with_b1_slayer
      b1_url = ENV["B1_API_URL"]
      uri = URI("#{b1_url}/Invoices?$filter=CardCode eq '#{card_code}'")

      request = Net::HTTP::Get.new(uri, { "Accept" => "application/json", "Cookie" => @b1_cookies })
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        result = JSON.parse(response.body)
        db_invoices = fetch_pending_invoices(tx_id)
        sap_invoices = result["value"]

        db_invoices.all? do |db_invoice|
          sap_invoices.any? do |sap_invoice|
            sap_invoice["DocumentLines"].any? { |line| line["ItemCode"] == map_item_code(db_invoice.description).first }
          end
        end
      else
        puts "Erro ao verificar notas fiscais no SAP: #{response.message}"
        false
      end
    rescue StandardError => e
      puts "Erro ao verificar notas fiscais no SAP: #{e.message}"
      false
    end

    def fetch_pending_invoices(tx_id)
      InvoiceNote.joins(:invoice_note_items, contract: :person)
                 .select('invoice_notes.id, people.tx_id, invoice_note_items.description, invoice_note_items.item_code, invoice_note_items.quantity, invoice_note_items.total_amount, invoice_notes.document_number, invoice_notes.issue_date')
                 .where(people: { tx_id: tx_id })
                 .where("invoice_notes.issue_date >= ?", 1.month.ago.beginning_of_month)
    end
  end
end
