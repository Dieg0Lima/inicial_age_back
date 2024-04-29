module AttendantActions
  class DeprovisionService
    def deprovision_onu(olt_id, gpon_index, sernum, user_id)
      ip = fetch_olt_with_ip(olt_id)
      return { success: false, error: "Erro ao obter IP da OLT." } unless ip
    
      check_response = check_ont_status(ip, gpon_index, sernum)
    
      if check_response[:success]
        full_ont_index = check_response[:ont_index] 
        deprovision_response = remove_onu(ip, full_ont_index)
        if deprovision_response[:success]
          { success: true }
        else
          { success: false, error: deprovision_response[:error] }
        end
      else
        { success: false, error: check_response[:error] }
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

    def check_ont_status(ip, gpon_index, expected_serial)
      command = "show equipment ont status pon #{gpon_index}"
      response = post_olt_command(ip, command)
    
      if response[:success]
        ont_ports = parse_ont_ports(response[:result])
        if ont_ports[:success]
          normalized_expected_serial = expected_serial.gsub(/[^a-zA-Z0-9]/, '').upcase
          matched_onu = ont_ports[:data].find do |onu|
            onu_serial = onu[:sernum].gsub(/[^a-zA-Z0-9]/, '').upcase
            onu_serial == normalized_expected_serial
          end
    
          if matched_onu
            full_ont_index = matched_onu[:ont_index]
            { success: true, message: "ONU found and serial matches", ont_index: full_ont_index }
          else
            { success: false, error: "No matching ONU found or serial mismatch", ont_index: nil }
          end
        else
          { success: false, error: ont_ports[:error], ont_index: nil }
        end
      else
        { success: false, error: response[:error], ont_index: nil }
      end
    end
    
    def parse_ont_ports(response)
      parsed_data = []
      lines = response.split("\n")
      header_found = false

      lines.each do |line|
        if header_found && line.strip.start_with?(/^\d+/)
          data = line.split(/\s+/)
          next unless data.size >= 10

          parsed_data << {
            gpon_index: data[0],
            ont_index: data[1],
            sernum: data[2],
            admin_status: data[3],
            oper_status: data[4],
            rx_level: data[5].to_f,
            distance: data[6].to_f,
            desc1: data[7],
            desc2: data[8],
            hostname: data[9],
          }
        elsif line.include?("----------")
          header_found = true
        end
      end

      if parsed_data.empty?
        { error: "No PON info available", success: false }
      else
        { success: true, data: parsed_data }
      end
    rescue => e
      { error: "Error parsing response: #{e.message}", success: false }
    end

    def remove_onu(ip, full_ont_index)
      command = <<-COMMAND
        configure equipment ont interface #{full_ont_index} admin-state down
        configure equipment ont no interface #{full_ont_index}
      COMMAND
    
      response = post_olt_command(ip, command)
      if response[:success]
        { success: true, message: "ONU deprovisioned successfully" }
      else
        { success: false, error: "Failed to deprovision ONU: #{response[:error]}" }
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
  end
end
