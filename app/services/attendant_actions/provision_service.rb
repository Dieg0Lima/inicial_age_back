require "open3"

module AttendantActions
  class ProvisionService
    def valid_olt_list
      AuthenticationAccessPoint.bsa_olts.map(&:olt_title_with_value)
    end

    def provision_onu(olt_id, slot, pon, port, contract, sernum, connection_id)
      missing_params = [olt_id, slot, pon, port, contract, sernum, connection_id].select(&:nil?)
      unless missing_params.empty?
        return { error: "Missing parameters: #{missing_params.join(", ")}" }
      end

      ip = fetch_olt_with_ip(olt_id)
      return { error: "Erro ao obter IP da OLT." } unless ip

      vlan_id = fetch_vlan_id_from_configuration(olt_id, slot, pon)
      return { error: "Nenhuma VLAN IPoE correspondente encontrada." } if vlan_id.nil?

      adjusted_sernum = sernum.sub(/^ALCL/, "")
      equipment_serial_with_prefix = "ALCL#{adjusted_sernum}"

      configure_response = configure_onu(ip, slot, pon, port, contract, adjusted_sernum, vlan_id)
      return configure_response unless configure_response[:success]

      if configure_response[:success]
        token_response = obtain_authentication_token(equipment_serial_with_prefix)
        return token_response unless token_response[:success]

        if token_response[:success]
          update_connection_response = update_connection(token_response[:token], connection_id, vlan_id, slot, pon, port, equipment_serial_with_prefix, olt_id)
          return update_connection_response
        else
          return { error: "Failed to obtain authentication token." }
        end
      else
        return { error: "Failed to configure ONT: #{configure_response[:error]}" }
      end
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

    def fetch_vlan_id_from_configuration(olt_id, slot, pon)
      access_point = AuthenticationAccessPoint.find(olt_id)
      return nil unless access_point

      configuration = access_point.configuration
      configuration = JSON.parse(configuration) if configuration.is_a?(String)

      slot_key = slot.to_s
      port_key = pon.to_s

      return nil unless configuration.key?(slot_key) && configuration[slot_key].key?(port_key)

      vlan_id = configuration[slot_key][port_key]["vlangerencia"]
      vlan_id
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

      additional_command = "..."
      additional_response = post_olt_command(ip, additional_command)
      if additional_response[:success]
        { success: true, message: "Configuration successful" }
      else
        { success: false, error: additional_response[:error], message: "Failed during additional configuration" }
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
  end
end
