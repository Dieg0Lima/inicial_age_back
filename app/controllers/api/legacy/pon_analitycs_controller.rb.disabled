module Api
  require "caxlsx"
  require "thread"
  require "open3"

  class PonAnalitycsController < ApplicationController
    include HTTParty
    base_uri "http://192.168.69.80:3000/"
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

    require "open3"

    require "concurrent"

    def analytics_optics
      Rails.logger.debug "Starting analytics_optics method."
      valid_olts = fetch_valid_olts
      Rails.logger.debug "Valid OLTS fetched: #{valid_olts.size}"

      excel_file_path = Rails.root.join("tmp", "OLT_OPTICS_#{Time.now.to_i}.xlsx")
      Rails.logger.debug "Excel file path: #{excel_file_path}"

      package = Axlsx::Package.new
      workbook = package.workbook
      sheet = workbook.add_worksheet(name: "OLT Optics")
      sheet.add_row ["OLT_Name", "ONT_Index", "RX_Signal_Level", "TX_Signal_Level", "Temperature", "ONU_Voltage", "Laser_Bias_Current", "OLT_RX_Signal_Level", "Serial Number", "Admin Status", "Oper Status", "ONT-OLT Distance", "Description 1", "Description 2", "Hostname"]

      valid_olts.each do |olt|
        process_ont_optics(olt, sheet)
      end

      package.serialize(excel_file_path)
      Rails.logger.debug "Excel file serialized."

      send_file excel_file_path, type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", filename: "OLT_OPTICS_#{Time.now.to_i}.xlsx", disposition: "attachment"
      Rails.logger.debug "Excel file sent to client."
    end

    def process_ont_optics(olt, workbook)
      username = ENV["OLT_USERNAME"]
      password = ENV["OLT_PASSWORD"]
      ip = fetch_ip_from_olt_id(olt[:id])

      Rails.logger.debug "IP for #{olt[:olt_name]}: #{ip}"
      return if ip.nil?

      script_path = Rails.root.join("scripts", "olt_command_executor.py").to_s

      begin
        command = "python3 #{script_path} #{ip.shellescape} #{username.shellescape} #{password.shellescape}"
        stdout, stderr, status = Open3.capture3(command)

        unless status.success?
          Rails.logger.error "Failed to execute command for OLT #{olt[:olt_name]}: #{stderr}"
          return
        end

        merged_data = JSON.parse(stdout)

        merged_data.each do |data|
          workbook.add_row [
            olt[:olt_name],             # OLT Name
            data["ont_idx"],            # ONT Index
            data["rx_signal_level"],    # RX Signal Level
            data["tx_signal_level"],    # TX Signal Level
            data["temperature"],        # Temperature
            data["ont_voltage"],        # ONU Voltage
            data["bias_current"],       # Laser Bias Current
            data["olt_rx_sig_level"],   # OLT RX Signal Level
            data["sernum"],             # Serial Number
            data["admin_status"],       # Admin Status
            data["oper_status"],        # Oper Status
            data["ont_olt_distance"],   # ONT-OLT Distance
            data["desc1"],              # Description 1
            data["desc2"],              # Description 2
            data["hostname"],           # hostname
          ]
        end
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse JSON from Python script: #{e.message}"
      rescue => e
        Rails.logger.error "An unexpected error occurred: #{e.message}"
      end
    end

    def extract_optics_data(output)
      output.scan(/(?<ont_idx>\S+)\s+(?<rx_signal_level>\S+)\s+(?<tx_signal_level>\S+)\s+(?<temperature>\S+)\s+(?<ont_voltage>\S+)\s+(?<bias_current>\S+)\s+(?<olt_rx_sig_level>\S+)/).map do |match|
        {
          "ont-idx" => match[0],
          "rx-signal-level" => match[1],
          "tx-signal-level" => match[2],
          "temperature" => match[3],
          "ont-voltage" => match[4],
          "bias-current" => match[5],
          "olt-rx-sig-level" => match[6],
        }
      end
    end

    def process_olt(olt, sheet)
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
            post_response = execute_olt_command(ip, command)

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
        .where(id: 23)
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
      end
    end

    def execute_olt_command(ip, command)
      self.class.post("/api/olt_command/", body: { ip: ip, command: command })
    end

    def handle_post_response(response)
      if response.success?
        yield(response.body)
      else
        render json: { error: "Erro ao executar o comando na OLT." }, status: :bad_request
      end
    end

    def determine_slot_range(olt_id)
      case olt_id
      when 5, 4, 3, 1
        (1..16)
      else
        (1..8)
      end
    end
  end
end
