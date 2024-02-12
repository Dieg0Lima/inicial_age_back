require 'caxlsx'

class PonAnalitycsController < ApplicationController
  include HTTParty
  base_uri 'http://192.168.69.80:3000'

  def execute_command
    command = params[:command]
    case command
    when 'analitycs_olt'
      analitycs_olt
    else
      render json: { error: "Comando não reconhecido: #{command}" }, status: :bad_request
    end
  end

  private

  def analitycs_olt
    ip = fetch_ip_from_olt_id(params[:id])
    return unless ip

    olt_name = AuthenticationAccessPoint.fetch_olt_name_by_id(params[:id])

    post_response = post_olt_command(ip, "show equipment ont status pon")
    handle_post_response(post_response) do |body|
      pon_details = extract_pon_details(body)

      package = Axlsx::Package.new
      workbook = package.workbook

      workbook.add_worksheet(name: "PON Details") do |sheet|
        sheet.add_row ["OLT Name", "PON", "ONT", "Serial", "Admin Status", "Oper Status", "Contrato", "Status"]
        pon_details.each do |detail|
          desc1 = detail[:desc1]
          desc1 = desc1.gsub(/\D/, '') unless desc1.nil?
          contract_details = fetch_client_details_by_contract(detail[:desc1])
          sheet.add_row [olt_name, detail[:slot], detail[:pon], detail[:serial], detail[:admin_status], detail[:oper_status], desc1, contract_details[:contract_status]]
        end
      end

      excel_file_path = Rails.root.join('tmp', "PON_Details_#{Time.now.to_i}.xlsx")
      package.serialize(excel_file_path)

      send_file excel_file_path, type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", filename: "PON_Details.xlsx", disposition: "attachment"
    end
  end


  def fetch_client_details_by_contract(contract_id)
    query = Contract
              .where(id: contract_id)
              .select(
                'contracts.id AS contract_id',
                'contracts.v_status AS contract_status'
              )
              .first

    if query
      {
        contract_id: query.contract_id,
        contract_status: query.contract_status
      }
    else
      { error: "Nenhum detalhe do contrato encontrado para o contrato #{contract_id}." }
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
      ([\d*]+|-)\s+                   # Desc1, considerando números ou '-' ou '*'
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
