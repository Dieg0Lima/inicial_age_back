module Api
  require "caxlsx"
  require "thread"

  class PonAnalitycsController < ApplicationController
    include HTTParty
    base_uri "http://localhost:3000/"
    before_action :set_semaphore

    def execute_command
      command = params[:command]
      case command
      when "analitycs_olt"
        analitycs_olt
      when "analytics_olt"
        analytics_olt
      when "analytics_optics"
        analytics_optics
      else
        render json: { error: "Comando não reconhecido: #{command}" }, status: :bad_request
      end
    end

    private

    def set_semaphore
      @semaphore = Mutex.new
    end

    def analitycs_olt
      olt_id = params[:olt_id]

      excel_file_path = Rails.root.join("tmp", "PON_Details_#{Time.now.to_i}.xlsx")
      package = Axlsx::Package.new
      workbook = package.workbook
      sheet = workbook.add_worksheet(name: "PON Details")
      sheet.add_row ["OLT_Name", "SLOT", "PON", "Serial", "Admin_Status", "Oper_Status", "Distance", "Contrato", "Status"]

      begin
        olt_info = fetch_olt(olt_id)
        if olt_info[:error]
          raise StandardError.new(olt_info[:error])
        end
        olt_name = olt_info[:olt_name]

        ip = fetch_ip_from_olt_id(olt_id)
        if ip.nil?
          raise StandardError.new("IP não encontrado para OLT com ID: #{olt_id}")
        end

        (1..8).each do |slot|
          (1..16).each do |pon|
            command = <<-COMMAND
                  environment inhibit-alarms
                  show equipment ont status pon 1/1/#{slot}/#{pon}
                COMMAND
            post_response = post_olt_command(ip, command)

            if post_response.body.include?("board is not planned")
              break
            end

            next unless post_response.success?

            pon_details = extract_pon_details(post_response.body)
            pon_details.each do |detail|
              desc1 = detail[:desc1].gsub(/\D/, "") unless detail[:desc1].nil?
              contract_details = fetch_client_details_by_contract(detail[:desc1])
              sheet.add_row [
                olt_name,
                "#{slot}",
                "#{pon}",
                detail[:serial],
                detail[:admin_status],
                detail[:oper_status],
                detail[:ont_olt_distance],
                desc1,
                contract_details.fetch(:contract_status, "N/A"),
              ]
            end
          end
        end
      rescue StandardError => e
        Rails.logger.error "Erro ao processar OLT com ID: #{olt_id} (IP: #{ip}): #{e.message}"
        sheet.add_row ["Erro ao processar OLT com ID: #{olt_id}", "Verifique os logs para mais detalhes"]
      end

      package.serialize(excel_file_path)

      send_data File.read(excel_file_path), type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", filename: "PON_Details.xlsx"
    end

    def analytics_olt
      valid_olts = fetch_valid_olts

      excel_file_path = Rails.root.join("tmp", "PON_Details_#{Time.now.to_i}.xlsx")
      package = Axlsx::Package.new
      workbook = package.workbook
      sheet = workbook.add_worksheet(name: "PON Details")
      sheet.add_row ["OLT_Name", "SLOT", "PON", "Serial", "Admin_Status", "Oper_Status", "OLT-RX-SIG Level", "Distance", "Contrato", "Status"]

      threads = []
      valid_olts.each_slice(4) do |olts_slice|
        olts_slice.each do |olt|
          threads << Thread.new { process_olt(olt, sheet) }
        end
        threads.each(&:join)
        threads.clear
      end

      @semaphore.synchronize do
        package.serialize(excel_file_path)
      end
      send_file excel_file_path, type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", filename: "PON_Details.xlsx", disposition: "attachment"
    end

    def analytics_optics
      valid_olts = fetch_valid_olts

      excel_file_path = Rails.root.join("tmp", "OLT_OPTICS_#{Time.now.to_i}.xlsx")
      package = Axlsx::Package.new
      workbook = package.workbook
      sheet = workbook.add_worksheet(name: "OLT Optics")
      sheet.add_row ["OLT_Name", "SLOT", "PON", "PORT", "ONU_TX_SIG_Level", "ONU_RX_SIG_Level", "OLT_RX_SIG_Level", "ONU_Temperature", "ONU_Voltage", "Laser_Bias_Current"]

      threads = []
      @semaphore = Mutex.new
      valid_olts.each_slice(1) do |olts_slice|
        olts_slice.each do |olt|
          threads << Thread.new { process_ont_optics(olt, sheet) }
        end
        threads.each(&:join)
        threads.clear
      end

      @semaphore.synchronize do
        package.serialize(excel_file_path)
      end
      send_file excel_file_path, type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", filename: "PON_Details.xlsx", disposition: "attachment"
    end

    def process_ont_optics(olt, sheet)
      olt_name = olt[:olt_name]
      ip = fetch_ip_from_olt_id(olt[:id])
      raise StandardError, "IP não encontrado para OLT #{olt_name}" if ip.nil?

      slot_range = (olt[:id] == 5 || olt[:id] == 4 || olt[:id] == 3 || olt[:id] == 1) ? (1..16) : (1..8)

      threads = []
      slot_range.each do |slot|
        threads << Thread.new do
          (1..16).each do |pon|
            command = "show equipment ont optics 1/1/#{slot}/#{pon}"
            post_response = post_olt_command(ip, command)

            break if post_response.body.include?("board is not planned")
            next unless post_response.success?

            pon_details = extract_ont_optics(post_response.body)

            @semaphore.synchronize do
              pon_details.each do |detail|
                sheet.add_row [
                                olt_name,
                                slot.to_s,
                                pon.to_s,
                                port.to_s,
                                detail[:tx_signal_level],
                                detail[:rx_signal_level],
                                detail[:olt_rx_sig_level],
                                detail[:ont_temperature],
                                detail[:ont_voltage],
                                detail[:laser_bias_curr],
                              ]
              end
            end
          end
        end
      end
      threads.each(&:join)
    rescue StandardError => e
      Rails.logger.error "Erro ao processar OLT #{olt_name}: #{e.message}"
      @semaphore.synchronize do
        sheet.add_row ["Erro ao processar OLT: #{olt_name}", "Verifique os logs para mais detalhes"]
      end
    end

    def process_olt(olt, sheet)
      olt_name = olt[:olt_name]
      begin
        ip = fetch_ip_from_olt_id(olt[:id])
        if ip.nil?
          raise StandardError.new("IP não encontrado para OLT #{olt_name}")
        end

        (1..16).each do |slot|
          (1..16).each do |pon|
            command = <<-COMMAND
                  environment inhibit-alarms
                  show equipment ont status pon 1/1/#{slot}/#{pon}
                COMMAND
            post_response = post_olt_command(ip, command)

            if post_response.body.include?("board is not planned")
              break
            end

            next unless post_response.success?

            pon_details = extract_pon_details(post_response.body)
            pon_details.each do |detail|
              desc1 = detail[:desc1]
              contract_details = fetch_client_details_by_contract(desc1)

              @semaphore.synchronize do
                sheet.add_row [
                  olt_name,
                  "#{slot}",
                  "#{pon}",
                  detail[:serial],
                  detail[:admin_status],
                  detail[:oper_status],
                  detail[:olt_rx_sig_level],
                  detail[:ont_olt_distance],
                  desc1,
                  contract_details.fetch(:contract_status, "N/A"),
                ]
              end
            end
          end
        end
      rescue StandardError => e
        Rails.logger.error "Erro ao processar OLT #{olt_name}: #{e.message}"
        @semaphore.synchronize do
          sheet.add_row ["Erro ao processar OLT: #{olt_name}", "Verifique os logs para mais detalhes"]
        end
      end
    end

    def fetch_client_details_by_contract(contract_id)
      query = Contract
        .where(id: contract_id)
        .select(
          "contracts.id AS contract_id",
          "contracts.v_status AS contract_status",
        )
        .first

      if query
        {
          contract_id: query.contract_id,
          contract_status: query.contract_status,
        }
      else
        { error: "Nenhum detalhe do contrato encontrado para o contrato #{contract_id}." }
      end
    end

    def fetch_olt(olt_id)
      olt = AuthenticationAccessPoint
        .where(id: olt_id)
        .select(:id, :title)
        .first

      if olt
        { id: olt.id, olt_name: olt.title }
      else
        { error: "Nenhuma OLT encontrada com o ID: #{olt_id}." }
      end
    end

    def fetch_valid_olts
      AuthenticationAccessPoint
        .where("title LIKE ?", "BSA%")
        .where.not(id: [2, 9, 7, 75, 77, 68, 69, 32, 67, 8, 75])
        .select(:id, :title)
        .map do |olt|
        { id: olt.id, olt_name: olt.title }
      end
    end

    def extract_pon_details(body)
      pon_details_regex =
        /(\d+\/\d+\/\d+\/\d+)\s+       # PON
        (\d+\/\d+\/\d+\/\d+\/\d+)\s+   # ONT
        (ALCL:[A-F0-9]+)\s+            # Serial Number
        (up|down)\s+                   # Admin Status
        (up|down|invalid)\s+           # Oper Status
        (-?\d+\.\d+|invalid)\s+        # OLT-RX-SIG Level (dbm)
        (-?\d+\.\d+|invalid)\s+        # ONT-OLT Distance (km)
        (\d+)\s+                       # Desc1,
        (-)\s+                         # Desc2,
        (\w+|undefined)/x              # Hostname

      matches = body.scan(pon_details_regex)

      pon_details = matches.map do |match|
        {
          slot: match[0],
          pon: match[1],
          serial: match[2],
          admin_status: match[3],
          oper_status: match[4],
          olt_rx_sig_level: match[5],
          ont_olt_distance: match[6],
          desc1: match[7],
          desc2: match[8],
          hostname: match[9],
        }
      end
    end

    def extract_ont_optics(body)
      optics_details_regex = /
        (\d+\/\d+\/\d+\/\d+\/\d+)\s+       # ont-idx
        (-?\d+\.\d+)\s+                    # rx-signal-level
        (-?\d+\.\d+)\s+                    # tx-signal-level
        (-?\d+\.\d+)\s+                    # ont-temperature
        (-?\d+\.\d+)\s+                    # ont-voltage
        (-?\d+\.\d+|\d+)\s+                # laser-bias-curr
        (-?\d+\.\d+)\s*                    # olt-rx-sig-level
      /x

      matches = body.scan(optics_details_regex)

      optics_details = matches.map do |match|
        {
          ont_idx: match[0],
          rx_signal_level: match[1],
          tx_signal_level: match[2],
          ont_temperature: match[3],
          ont_voltage: match[4],
          laser_bias_curr: match[5],
          olt_rx_sig_level: match[6],
        }
      end
    end

    def fetch_ip_from_olt_id(olt_id)
      response = self.class.get("/api/equipamento/#{olt_id}")
      if response.success?
        JSON.parse(response.body)["ip"]
      else
        Rails.logger.error "Erro ao obter o IP do equipamento com ID: #{olt_id}"
        nil
      end
    end

    def post_olt_command(ip, command)
      self.class.post("/api/olt_command/", body: { ip: ip, command: command })
    end

    def handle_post_response(response)
      if response.success?
        yield(response.body)
      else
        render json: { error: "Erro ao executar o comando na OLT." }, status: :bad_request
      end
    end
  end
end
