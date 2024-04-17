module Api
  class EquipmentCommandController < ApplicationController
    include HTTParty
    base_uri "http://localhost:3000"

    def execute_command
      command = params[:command]
      case command
      when "unprovision_list"
        unprovision_list
      when "availability_pon"
        availability_pon
      when "provision_onu"
        provision_onu
      when "unprovision_onu"
        unprovision_onu
      when "potency_onu"
        potency_onu
      when "distance_onu"
        distance_onu
      when "reboot_onu"
        reboot_onu
      when "management_onu"
        management_onu
      else
        render json: { error: "Comando não reconhecido: #{command}" }, status: :bad_request
      end
    end

    def fetch_ip_from_olt_id(olt_id)
      response = self.class.get("/api/equipamento/#{olt_id}")
      if response.success?
        JSON.parse(response.body)["ip"]
      else
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
        { error: "Erro ao executar o comando na OLT." }
      end
    end

    def fetch_vlan_id_from_configuration(id, slot, port)
      access_point = AuthenticationAccessPoint.find(id)
      return nil unless access_point

      configuration = access_point.configuration

      slot_key = slot.to_s
      port_key = port.to_s

      return nil unless configuration.key?(slot_key)

      slot_config = configuration[slot_key]

      return nil unless slot_config.key?(port_key)

      port_config = slot_config[port_key]

      vlan_id = port_config["vlangerencia"]

      vlan_id.nil? ? nil : vlan_id
    end

    def configure_onu(ip, params)
      slot, pon, port, contract, sernum, vlan_id = params.values_at(:slot, :pon, :port, :contract, :sernum, :vlan_id)
      command = <<-COMMAND
      configure equipment ont interface 1/1/#{slot}/#{pon}/#{port} desc1 "#{contract}" desc2 "-" sernum ALCL:#{sernum} subslocid WILDCARD sw-ver-pland auto sw-dnload-version disabled
      configure equipment ont interface 1/1/#{slot}/#{pon}/#{port} admin-state up optics-hist enable pland-cfgfile1 auto pland-cfgfile2 auto dnload-cfgfile1 auto dnload-cfgfile2 auto
      configure equipment ont slot 1/1/#{slot}/#{pon}/#{port}/14 planned-card-type veip plndnumdataports 1 plndnumvoiceports 0
      configure interface port uni:1/1/#{slot}/#{pon}/#{port}/14/1 admin-up
      configure qos interface 1/1/#{slot}/#{pon}/#{port}/14/1 upstream-queue 0 bandwidth-profile name:HSI_1G_UP
      configure bridge port 1/1/#{slot}/#{pon}/#{port}/14/1 max-unicast-mac 4 max-committed-mac 1
      configure bridge port 1/1/#{slot}/#{pon}/#{port}/14/1 vlan-id 41 tag single-tagged l2fwder-vlan #{vlan_id} vlan-scope local
      configure bridge port 1/1/#{slot}/#{pon}/#{port}/14/1 vlan-id #{vlan_id} tag single-tagged
        COMMAND
      post_response = post_olt_command(ip, command)
      post_response.success?
    end

    def render_error(message, status = :internal_server_error)
      render json: { error: message }, status: status
    end

    def command_execution_success?(response_body)
      !response_body.include?("invalid token") && !response_body.include?("instance does not exist")
    end

    Dotenv.load

    def fetch_management_ip(sernum)
      mikrotik_ips = ENV["MIKROTIK_IPS"].split(",")
      ssh_username = ENV["SSH_USERNAME"]
      ssh_password = ENV["SSH_PASSWORD"]
      command = "/ip dhcp-server lease print where agent-circuit-id=#{sernum}"

      queue = Queue.new
      threads = []

      mikrotik_ips.each do |ip|
        threads << Thread.new do
          begin
            Net::SSH.start(ip, ssh_username, password: ssh_password) do |ssh|
              output = ssh.exec!(command)
              ip_match = output.match(/\d+ D (\d+\.\d+\.\d+\.\d+)/)
              queue.push(ip_match[1]) if ip_match
            end
          rescue StandardError => e
            puts "Erro ao conectar ou executar o comando no equipamento #{ip}: #{e.message}"
          end
        end
      end

      threads.each(&:join)

      queue.empty? ? nil : queue.pop
    end

    private

    def unprovision_list
      ip = fetch_ip_from_olt_id(params[:id])
      return unless ip

      post_response = post_olt_command(ip, "show pon unprovision-onu")
      handle_post_response(post_response) do |body|
        data = body.scan(/(\d+)\s+1\/1\/(\d+)\/(\d+)\s+([A-Z0-9]+)/).reject { |match| match.empty? }
        structured_data = data.map do |alarm_idx, slot, pon, serial|
          {
            path: "1/1/#{slot}/#{pon}",
            slot: slot,
            pon: pon,
            serial: serial,
            status: "Unprovisioned",
          }
        end
        render json: { success: true, response: structured_data }
      end
    end

    def availability_pon
      ip = fetch_ip_from_olt_id(params[:id])
      return unless ip

      slot = params[:slot]
      pon = params[:pon]
      post_response = post_olt_command(ip, "show equipment ont status pon 1/1/#{slot}/#{pon}")
      handle_post_response(post_response) do |body|
        used_slots_data = body.scan(/(1\/1\/(\d+)\/(\d+)\/(\d+))\s+ALCL:[A-F0-9]+/)
        used_slots = used_slots_data.map { |entry| entry[0] }

        available_slots = (1..128).map do |port|
          slot_path = "1/1/#{slot}/#{pon}/#{port}"
          unless used_slots.include?(slot_path)
            {
              slot: slot,
              pon: pon,
              port: port.to_s,
              status: "Disponivel",
            }
          end
        end.compact

        render json: { success: true, response: available_slots }
      end
    end

    def provision_onu
      ip = fetch_ip_from_olt_id(params[:id])
      return unless ip

      vlan_id = fetch_vlan_id_from_configuration(params[:id], params[:slot], params[:port])
      return render_error("Nenhuma VLAN IPoE correspondente encontrada.", :not_found) if vlan_id.nil?

      adjusted_sernum = params[:sernum]&.sub(/^ALCL/, "")

      equipment_serial_with_prefix = "ALCL#{adjusted_sernum}"

      if configure_onu(ip, params.slice(:slot, :pon, :port, :contract).merge(sernum: adjusted_sernum, vlan_id: vlan_id))
        token_response = HTTParty.post("https://erp.agetelecom.com.br:45700/connect/token",
                                       body: { grant_type: "client_credentials", scope: "syngw", client_id: "1fa86391-e47d-4aab-a3f0-3c45f6927c88", client_secret: "c8438327-e0b3-4792-9d35-6543fcc69b56", syndata: "TWpNMU9EYzVaakk1T0dSaU1USmxaalprWldFd00ySTFZV1JsTTJRMFptUT06WlhsS1ZHVlhOVWxpTTA0d1NXcHZhVTFxUVRKTWFrbDNUa00wZVU1RVozVlBSRmxwVEVOS1ZHVlhOVVZaYVVrMlNXMVNhVnBYTVhkTlJFRXdUMFJyYVV4RFNrVlpiRkkxWTBkVmFVOXBTbmRpTTA0d1dqTktiR041U2prPTpaVGhrTWpNMVlqazBZemxpTkRObVpEZzNNRGxrTWpZMll6QXhNR00zTUdVPQ==" },
                                       headers: { "Content-Type" => "application/x-www-form-urlencoded" })
        if token_response.success?
          token = token_response["access_token"]

          update_connection_payload = {
            id: params[:connection_id],
            equipmentType: 15,
            oltId: params[:port].to_i,
            slotOlt: params[:slot].to_i,
            portOlt: params[:pon].to_i,
            isIPoE: true,
            authenticationAccessPointId: params[:id].to_i,
            equipmentSerialNumber: equipment_serial_with_prefix,
            user: equipment_serial_with_prefix,
          }

          update_connection_response = HTTParty.put("https://erp.agetelecom.com.br:45715/external/integrations/thirdparty/updateconnection/#{params[:connection_id]}",
                                                    body: update_connection_payload.to_json,
                                                    headers: { "Content-Type" => "application/json", "Authorization" => "Bearer #{token}" })

          if update_connection_response.success?
            render json: { success: true }, status: :ok
          else
            render_error("Erro ao enviar requisição adicional.", :bad_request)
          end
        else
          render_error("Falha ao obter token de autenticação.", :unauthorized)
        end
      else
        render_error("Erro ao executar o comando na OLT.", :bad_request)
      end
    end

    def unprovision_onu
      ip = fetch_ip_from_olt_id(params[:id])
      return render json: { error: true, message: "Equipamento não encontrado." }, status: :not_found unless ip

      slot = params[:slot]
      pon = params[:pon]
      port = params[:port]

      command = <<-COMMAND
        configure equipment ont interface 1/1/#{slot}/#{pon}/#{port} admin-state down
        configure equipment ont no interface 1/1/#{slot}/#{pon}/#{port}
      COMMAND

      post_response = post_olt_command(ip, command)
      handle_post_response(post_response) do |body|
        if command_execution_success?(body)
          render json: { success: true, message: "ONU desprovisionado com sucesso." }
        else
          render json: { error: true, message: "Falha ao desprovisionar ONU." }, status: :unprocessable_entity
        end
      end
    end

    def reboot_onu
      ip = fetch_ip_from_olt_id(params[:id])
      return render json: { error: true, message: "Equipamento não encontrado." }, status: :not_found unless ip

      slot = params[:slot]
      pon = params[:pon]
      port = params[:port]

      command = <<-COMMAND
          admin equipment ont interface 1/1/#{slot}/#{pon}/#{port} reboot with-active-image
        COMMAND

      post_response = post_olt_command(ip, command)
      handle_post_response(post_response) do |body|
        if command_execution_success?(body)
          render json: { success: true, message: "ONU reiniciada com sucesso." }
        else
          render json: { error: true, message: "Falha ao reiniciar ONU." }, status: :unprocessable_entity
        end
      end
    end

    def management_onu
      ip = fetch_management_ip(params[:sernum])

      if ip
        render json: { success: true, message: "IP de gerência encontrado.", ip: ip }
      else
        render json: { error: true, message: "Equipamento não encontrado." }, status: :not_found
      end
    end

    def potency_onu
      ip = fetch_ip_from_olt_id(params[:equipment_id])
      return render json: { success: false, message: "IP não encontrado." } unless ip

      slot = params[:slot]
      pon = params[:pon]
      port = params[:olt_id]

      command = <<-COMMAND
        show equipment ont optics 1/1/#{slot}/#{pon}/#{port}
      COMMAND

      post_response = post_olt_command(ip, command)
      handle_post_response(post_response) do |body|
        match_data = body.match(/1\/1\/#{slot}\/#{pon}\/#{port}\s+(-?\d+\.\d+)/)

        if match_data && match_data[1]
          rx_signal_level = match_data[1]
          render json: { success: true, rx_signal_level: rx_signal_level }
        else
          render json: { success: false, message: "Não foi possível extrair o rx_signal_level corretamente." }
        end
      end
    end

    def distance_onu
      ip = fetch_ip_from_olt_id(params[:equipment_id])
      return render json: { success: false, message: "IP não encontrado." } unless ip

      slot = params[:slot]
      pon = params[:pon]
      port = params[:olt_id]

      command = <<-COMMAND
          show equipment ont optics 1/1/#{slot}/#{pon}/#{port}
        COMMAND

      post_response = post_olt_command(ip, command)
      handle_post_response(post_response) do |body|
        match_data = body.match(/1\/1\/#{slot}\/#{pon}\/#{port}\s+(-?\d+\.\d+)/)

        if match_data && match_data[2]
          ont_distantce = match_data[2]
          render json: { success: true, ont_distantce: ont_distantce }
        else
          render json: { success: false, message: "Não foi possível extrair o ont_distantce corretamente." }
        end
      end
    end
  end
end
