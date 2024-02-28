require 'caxlsx'
require 'thread'

class PonAnalitycsController < ApplicationController
  include HTTParty
  base_uri 'http://192.168.69.80:3000'
  before_action :set_semaphore

  def execute_command
    command = params[:command]
    case command
    when 'analitycs_olt'
      analitycs_olt
    when 'analytics_olt'
      analytics_olt
    else
      render json: { error: "Comando não reconhecido: #{command}" }, status: :bad_request
    end
  end

  private

    def set_semaphore
      @semaphore = Mutex.new
    end

  def analitycs_olt
    valid_olts = fetch_valid_olts

    excel_file_path = Rails.root.join('tmp', "PON_Details_#{Time.now.to_i}.xlsx")
    package = Axlsx::Package.new
    workbook = package.workbook
    sheet = workbook.add_worksheet(name: "PON Details")
    sheet.add_row ["OLT_Name", "SLOT", "PON", "Serial", "Admin_Status", "Oper_Status", "Distance", "Contrato", "Status"]

    valid_olts.each do |olt|
      olt_name = olt[:olt_name]

      begin
        ip = fetch_ip_from_olt_id(olt[:id])
        if ip.nil?
          raise StandardError.new("IP não encontrado para OLT #{olt_name}")
        end

        (1..16).each do |slot|
          (1..16).each do |pon|
            command = "show equipment ont status pon 1/1/#{slot}/#{pon}"
            post_response = post_olt_command(ip, command)

            if post_response.body.include?("board is not planned")
              break
            end

            next unless post_response.success?

            pon_details = extract_pon_details(post_response.body)
            pon_details.each do |detail|
              desc1 = detail[:desc1].gsub(/\D/, '') unless detail[:desc1].nil?
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
                contract_details.fetch(:contract_status, "N/A")
              ]
            end
          end
        end
      rescue StandardError => e
        Rails.logger.error "Erro ao processar OLT #{olt_name} (IP: #{ip}): #{e.message}"
        sheet.add_row ["Erro ao processar OLT: #{olt_name}", "Verifique os logs para mais detalhes"]
      end
    end

    package.serialize(excel_file_path)
    send_file excel_file_path, type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", filename: "PON_Details.xlsx", disposition: "attachment"
  end

  def analytics_olt
      valid_olts = fetch_valid_olts

      excel_file_path = Rails.root.join('tmp', "PON_Details_#{Time.now.to_i}.xlsx")
      package = Axlsx::Package.new
      workbook = package.workbook
      sheet = workbook.add_worksheet(name: "PON Details")
      sheet.add_row ["OLT_Name", "SLOT", "PON", "Serial", "Admin_Status", "Oper_Status", "Distance", "Contrato", "Status"]

      threads = []
      valid_olts.each_slice(1) do |olts_slice|
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

    def process_olt(olt, sheet)
      olt_name = olt[:olt_name]
      begin
        ip = fetch_ip_from_olt_id(olt[:id])
        if ip.nil?
          raise StandardError.new("IP não encontrado para OLT #{olt_name}")
        end

        (1..16).each do |slot|
          (1..16).each do |pon|
            command = "show equipment ont status pon 1/1/#{slot}/#{pon}"
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
              desc1 = detail[:desc1].gsub(/\D/, '') unless detail[:desc1].nil?
              contract_details = fetch_client_details_by_contract(detail[:desc1])

              @semaphore.synchronize do
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
                  contract_details.fetch(:service_tag, "N/A")
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
              .inner(:contract_service_tag)
              .select(
                'contracts.id AS contract_id',
                'contracts.v_status AS contract_status',
                'contract_service_tag AS service_tag'
              )
              .first

    if query
      {
        contract_id: query.contract_id,
        contract_status: query.contract_status
        service_tag: query.service_tag
      }
    else
      { error: "Nenhum detalhe do contrato encontrado para o contrato #{contract_id}." }
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
      /(\d+\/\d+\/\d+\/\d+)\s+    # PON
      (\d+\/\d+\/\d+\/\d+\/\d+)\s+  # ONT
      (ALCL:[A-F0-9]+)\s+          # Serial Number
      (up|down)\s+                 # Admin Status
      (up|down|invalid)\s+         # Oper Status
      (-?\d+\.\d+|invalid)\s+      # OLT-RX-SIG Level (dbm), considerando 'invalid' e números com possível sinal negativo
      (-?\d+\.\d+|invalid)\s+      # ONT-OLT Distance (km), mesmo que acima
      (\d+|-)\s+                   # Desc1, ajustado para capturar qualquer quantidade de dígitos ou '-'
      (-)\s*                       # Desc2, considerando '-' ou espaço
      (\w+|undefined)/x            # Hostname, pode ser 'undefined' ou uma palavra

    matches = body.scan(pon_details_regex)

    pon_details = matches.reject { |match| match.include?("alarm") }

    pon_details.map do |match|
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
        hostname: match[9]
      }
    end
  end

  def fetch_ip_from_olt_id(olt_id)
    response = self.class.get("/equipamento/#{olt_id}")
    if response.success?
      JSON.parse(response.body)['ip']
    else
      render json: { error: "Erro ao obter o IP do equipamento." }, status: :bad_request
      nil
    end
  end

  def post_olt_command(ip, command)
    self.class.post("/olt_command/", body: { ip: ip, command: command })
  end

  def handle_post_response(response)
    if response.success?
      yield(response.body)
    else
      render json: { error: "Erro ao executar o comando na OLT." }, status: :bad_request
    end
  end
end
