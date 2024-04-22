module AttendantActions
  class DeprovisionService
    def deprovision_onu(olt_id, gpon_index, sernum, user_id)
      ip = fetch_olt_with_ip(olt_id)
      response = check_ont_status(ip, gpon_index, sernum)

      if response[:success]
        deprovision_response = remove_onu(ip, gpon_index)
        if deprovision_response[:success]
          { success: true }
        else
          { success: false, error: deprovision_response[:error] }
        end
      else
        { success: false, error: response[:error] }
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

    def check_ont_status(ip, gpon_index, expected_ont_index, expected_serial)
      command = "show equipment ont status pon #{gpon_index}"
      response = post_olt_command(ip, command)

      if response[:success]
        ont_ports = parse_ont_ports(response[:result])
        if ont_ports[:success]
          matched_onu = ont_ports[:data].find { |onu| onu[:ont_index] == expected_ont_index && onu[:sernum].include?(expected_serial) }
          if matched_onu
            { success: true, message: "ONU found and serial matches", onu_details: matched_onu }
          else
            { success: false, error: "No matching ONU found or serial mismatch", onu_details: nil }
          end
        else
          { success: false, error: ont_ports[:error], onu_details: nil }
        end
      else
        { success: false, error: response[:error], onu_details: nil }
      end
    end

    def parse_ont_ports(response)
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

      if parsed_data.empty?
        { error: "No PON info available", success: false }
      else
        { success: true, data: parsed_data }
      end
    rescue => e
      { error: "Error parsing response: #{e.message}", success: false }
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
