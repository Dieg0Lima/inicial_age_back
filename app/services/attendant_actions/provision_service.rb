require "open3"

module AttendantActions
  class ProvisionService
    def valid_olt_list
      AuthenticationAccessPoint.bsa_olts.map(&:olt_title_with_value)
    end

    def provision_onu(olt_id, contract, sernum, connection_id, user_id, cto = nil)
      missing_params = [olt_id, contract, sernum, connection_id].select(&:nil?)
      return { error: "Missing parameters: #{missing_params.join(", ")}" } unless missing_params.empty?
    
      ip = fetch_olt_with_ip(olt_id)
      return { error: "Erro ao obter IP da OLT." } unless ip
    
      position_check = check_onu_position(ip, sernum)
      return position_check unless position_check[:success]
    
      gpon_index = position_check[:details][:gpon_index]
      _, _, slot, pon = gpon_index.split("/")
    
      ont_status = check_ont_status(ip, "1/1/#{slot}/#{pon}")
      return ont_status unless ont_status[:success]
    
      if ont_status[:available_ports].nil? || ont_status[:available_ports].empty?
        return { error: "No available ports found." }
      end
    
      port = ont_status[:available_ports].first
      vlan_id = fetch_vlan_id_from_configuration(olt_id, slot, pon)
      return { error: "Nenhuma VLAN IPoE correspondente encontrada." } if vlan_id.nil?
    
      adjusted_sernum = sernum.sub(/^ALCL/, "")
      equipment_serial_with_prefix = "ALCL#{adjusted_sernum}"
    
      configure_response = configure_onu(ip, slot, pon, port, contract, adjusted_sernum, vlan_id)
      return configure_response unless configure_response[:success]
    
      token_response = obtain_authentication_token(equipment_serial_with_prefix)
      return token_response unless token_response[:success]
    
      update_connection_response = update_connection(token_response[:token], connection_id, vlan_id, slot, pon, port, equipment_serial_with_prefix, olt_id)
      return update_connection_response unless update_connection_response[:success]
    
      create_or_update_onu(connection_id, olt_id, contract, sernum, slot, pon, port, user_id, cto)
    
      { success: true, message: "ONU provisionada com sucesso." }
    end

    private

    def fetch_olt_with_ip(olt_id)
      ip_address = AuthenticationIp
        .joins(:authentication_access_points)
        .where(authentication_access_points: { id: olt_id })
        .pluck(:ip)
        .first

      ip_address
    end

    def check_onu_position(ip, sernum)
      command = "show pon unprovision-onu"
      response = post_olt_command(ip, command)

      if response[:success]
        details = parse_unprovisioned_onus(response[:result])
        onu_details = details.find { |detail| detail[:sernum].include?(sernum) }
        if onu_details
          return { success: true, details: onu_details }
        else
          return { success: false, error: "ONU não se encontra na listagem de desprovisionados." }
        end
      else
        return { success: false, error: response[:error] }
      end
    end

    def check_ont_status(ip, gpon_index)
      command = "show equipment ont status pon #{gpon_index}"
      response = post_olt_command(ip, command)
    
      return { success: false, error: response[:error], available_ports: [] } unless response[:success]
    
      ont_ports = parse_ont_ports(response[:result])
    
      return { success: false, error: ont_ports[:error], available_ports: [] } unless ont_ports[:success]
    
      occupied_ports = ont_ports[:data]
      available_ports = find_available_ports(occupied_ports)
      { success: true, available_ports: available_ports }
    end
    
    def parse_ont_ports(response)
      begin
        parsed_data = []
    
        lines = response.split("\n")
        lines.each do |line|
          if line =~ /^\d+\/\d+\/\d+\/\d+/
            data = line.match(/(\d+\/\d+\/\d+\/\d+) (\d+\/\d+\/\d+\/\d+\/\d+) (\w+):(\w+) (\w+) (\w+) ([-\.\d]+) ([-\.\d]+) (\d+) - (\w+)/)
            next unless data
    
            parsed_data << {
              gpon_index: data[1],
              ont_index: data[2],
              sernum: data[3],
              admin_status: data[5],
              oper_status: data[6],
              rx_level: data[7].to_f,
              distance: data[8].to_f,
              desc1: data[9],
              hostname: data[10],
            }
          end
        end
    
        if response.include?("pon count : 0")
          return { success: true, data: parsed_data }
        end
    
        if parsed_data.empty?
          { success: false, error: "No PON info available" }
        else
          { success: true, data: parsed_data }
        end
      rescue => e
        { success: false, error: "Error parsing response: #{e.message}" }
      end
    end
    
    def find_available_ports(occupied_ports)
      all_ports = (1..128).to_a
      occupied_port_numbers = occupied_ports.map { |p| p[:ont_index].split("/").last.to_i }
      available_ports = all_ports - occupied_port_numbers
      available_ports
    end
    
    
    def get_available_port(ip, slot, pon)
      full_gpon_index = "1/1/#{slot}/#{pon}"
      ont_status = check_ont_status(ip, full_gpon_index)
    
      return { error: "Failed to get ONT status: #{ont_status[:error]}" } unless ont_status[:success]
    
      if ont_status[:available_ports].nil? || ont_status[:available_ports].empty?
        return { error: "No available ports found." }
      end
    
      port = ont_status[:available_ports].first
      { success: true, available_port: port }
    end

    def parse_unprovisioned_onus(raw_output)
      raw_output.lines.map do |line|
        next unless line.strip.match(/\d+\s+(\d+\/\d+\/\d+\/\d+)\s+(\w+)\s+/)
        {
          gpon_index: $1,
          sernum: $2,
        }
      end.compact
    end

    def fetch_vlan_id_from_configuration(olt_id, slot, pon)
      access_point = AuthenticationAccessPoint.find_by(id: olt_id)

      return nil unless access_point

      begin
        configuration = JSON.parse(access_point.configuration) if access_point.configuration.is_a?(String)
      rescue JSON::ParserError
        return nil
      end

      vlan_config = configuration&.dig(slot.to_s, pon.to_s)

      vlan_config ? vlan_config["vlangerencia"] : nil
    end

    def configure_onu(ip, slot, pon, port, contract, adjusted_sernum, vlan_id)
      command = <<-COMMAND
        configure equipment ont interface 1/1/#{slot}/#{pon}/#{port} desc1 "#{contract}" desc2 "-" sernum ALCL:#{adjusted_sernum} subslocid WILDCARD sw-ver-pland auto sw-dnload-version disabled
        configure equipment ont interface 1/1/#{slot}/#{pon}/#{port} admin-state up optics-hist enable pland-cfgfile1 auto pland-cfgfile2 auto dnload-cfgfile1 auto dnload-cfgfile2 auto
        configure equipment ont slot 1/1/#{slot}/#{pon}/#{port}/14 planned-card-type veip plndnumdataports 1 plndnumvoiceports 0
        configure interface port uni:1/1/#{slot}/#{pon}/#{port}/14/1 admin-up
        configure qos interface 1/1/#{slot}/#{pon}/#{port}/14/1 upstream-queue 0 bandwidth-profile name:HSI_1G_UP
        configure bridge port 1/1/#{slot}/#{pon}/#{port}/14/1 max-unicast-mac 4 max-committed-mac 1
        configure bridge port 1/1/#{slot}/#{pon}/#{port}/14/1 vlan-id 41 tag single-tagged l2fwder-vlan #{vlan_id} vlan-scope local
        configure bridge port 1/1/#{slot}/#{pon}/#{port}/14/1 vlan-id #{vlan_id} tag single-tagged
      COMMAND
      response = post_olt_command(ip, command)
      unless response[:success]
        return { error: "Failed to configure ONT: #{response[:error]}" }
      end
    end

    def post_olt_command(ip, command)
      olt_command_service = OltServices::OltCommandService.new
      response = olt_command_service.execute_command(ip, command)

      if response[:result].include?("Error :")
        error_message = response[:result].match(/Error : (.+)/)[1].strip
        { success: false, error: error_message }
      else
        { success: true, result: response[:result] }
      end
    end

    def obtain_authentication_token(equipment_serial_with_prefix)
      client_id = ENV["CLIENT_ID_VOALLE"]
      client_secret = ENV["CLIENT_SECRET_VOALLE"]
      syndata = ENV["SYNDATA_VOALLE"]

      token_response = HTTParty.post("https://erp.agetelecom.com.br:45700/connect/token",
                                     body: { grant_type: "client_credentials", scope: "syngw", client_id: client_id, client_secret: client_secret, syndata: syndata },
                                     headers: { "Content-Type": "application/x-www-form-urlencoded" })

      if token_response.success?
        { success: true, token: token_response["access_token"] }
      else
        { success: false, error: "Failed to obtain authentication token." }
      end
    end

    def update_connection(token, connection_id, vlan_id, slot, pon, port, equipment_serial_with_prefix, olt_id)
      update_connection_payload = {
        id: connection_id,
        equipmentType: 15,
        oltId: port.to_i,
        slotOlt: slot.to_i,
        portOlt: pon.to_i,
        isIPoE: true,
        authenticationSplitterId: 0,
        updateConnectionParameter: true,
        authenticationAccessPointId: olt_id.to_i,
        equipmentSerialNumber: equipment_serial_with_prefix,
        user: equipment_serial_with_prefix,
      }

      update_connection_response = HTTParty.put("https://erp.agetelecom.com.br:45715/external/integrations/thirdparty/updateconnection/#{connection_id}",
                                                body: update_connection_payload.to_json,
                                                headers: { "Content-Type": "application/json", "Authorization" => "Bearer #{token}" })

      if update_connection_response.success?
        {
          success: true,
          status: update_connection_response.code,
          body: update_connection_response.body,
          headers: update_connection_response.headers.to_h,
        }
      else
        {
          success: false,
          error: "Failed to update connection.",
          status: update_connection_response.code,
          body: update_connection_response.body,
          headers: update_connection_response.headers.to_h,
        }
      end
    end

    def create_or_update_onu(connection_id, olt_id, contract, sernum, slot, pon, port, user_id, cto)
      onu = ProvisionOnu.find_or_initialize_by(connection_id: connection_id, sernum: sernum)
      onu.update(
        olt_id: olt_id,
        contract: contract,
        slot: slot.to_i,
        pon: pon.to_i,
        port: port.to_i,
        provisioned_by: user_id,
        cto: cto,
      )
    end
  end
end
