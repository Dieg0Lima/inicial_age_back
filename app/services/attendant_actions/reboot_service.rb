module AttendantActions
  class RebootService
    def reboot_onu(olt_id, slot, pon, port, sernum, user_id)
      ip = fetch_olt_with_ip(olt_id)
      return { success: false, error: "Erro ao obter IP da OLT." } unless ip

      gpon_index = "1/1/#{slot}/#{pon}"

      check_response = check_ont_status(ip, gpon_index, sernum)

      if check_response[:success]
        reboot_response = restart_onu(ip, gpon_index, port)
        if reboot_response[:success]
          { success: true, message: "ONU Rebooted Successfully" }
        else
          { success: false, error: reboot_response[:error] }
        end
      else
        { success: false, error: check_response[:error] }
      end
    end

    private

    def fetch_olt_with_ip(olt_id)
      AuthenticationIp
        .joins(:authentication_access_points)
        .where(authentication_access_points: { id: olt_id })
        .pluck(:ip)
        .first
    end

    def check_ont_status(ip, gpon_index, expected_serial)
      command = "show equipment ont status pon #{gpon_index}"
      response = post_olt_command(ip, command)

      if response[:success]
        ont_ports = parse_ont_ports(response[:result])
        if ont_ports[:success]
          normalized_expected_serial = expected_serial.gsub(/[^a-zA-Z0-9]/, "").upcase

          matched_onu = ont_ports[:data].find do |onu|
            onu_serial = onu[:sernum].gsub(/[^a-zA-Z0-9]/, "").upcase

            onu[:ont_index].start_with?(gpon_index) && onu_serial == normalized_expected_serial
          end

          if matched_onu
            { success: true, message: "ONU found at the specified position and serial matches", ont_index: matched_onu[:ont_index] }
          else
            Rails.logger.info "No matching ONU found. Data: #{ont_ports[:data].map { |onu| onu[:ont_index] + " " + onu[:sernum] }}"
            { success: false, error: "No matching ONU found at the specified position or serial mismatch", ont_index: nil }
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

    def restart_onu(ip, gpon_index, port)
      full_ont_index = "#{gpon_index}/#{port}"
      command = <<-COMMAND
          admin equipment ont interface #{full_ont_index} reboot with-active-image
        COMMAND

      response = post_olt_command(ip, command)
      if response[:success]
        { success: true, message: "ONU Rebooted Successfully" }
      else
        { success: false, error: "Failed to reboot ONU: #{response[:error]}" }
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
