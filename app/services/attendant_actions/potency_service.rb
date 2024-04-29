module AttendantActions
  class PotencyService
    def fetch_onu_power(olt_id, slot, pon, port, sernum)
      ip = fetch_olt_with_ip(olt_id)
      return { error: "Error fetching OLT IP." } unless ip

      unprovisioned_status = check_onu_unprovisioned_status(ip, sernum)
      if unprovisioned_status[:error]
        return unprovisioned_status
      elsif unprovisioned_status[:success] && unprovisioned_status[:status] == :unprovisioned
        return { success: true, message: "ONU Desprovisionada", power: "Desprovisionado" }
      elsif unprovisioned_status[:success]
        position_check = check_onu_position(ip, slot, pon, sernum)
        return position_check unless position_check[:success]

        power_index = "1/1/#{slot}/#{pon}/#{port}"
        power_response = fetch_power(ip, power_index)
        Rails.logger.debug "Power response type: #{power_response.class} - Content: #{power_response.inspect}"

        unless power_response.is_a?(Hash) && power_response[:success]
          Rails.logger.error "Failed to fetch ONU power: #{power_response[:error] || power_response[:message]}"
          return { error: "Failed to fetch ONU power: #{power_response[:error] || power_response[:message]}" }
        end

        { success: true, message: "ONU power fetched successfully.", power: power_response[:rx_signal_level] }
      else
        { error: "ONU status check failed: #{unprovisioned_status[:message]}" }
      end
    end

    private

    def fetch_olt_with_ip(olt_id)
      ip = AuthenticationIp.joins(:authentication_access_points).where(authentication_access_points: { id: olt_id }).pluck(:ip).first
      Rails.logger.debug "Fetched IP for OLT ID #{olt_id}: #{ip}"
      ip
    end

    def check_onu_unprovisioned_status(ip, sernum)
      command = "show pon unprovision-onu"
      Rails.logger.debug "Sending command to OLT: #{command}"
      response = post_olt_command(ip, command)

      if response[:success]
        Rails.logger.debug "Command response received: #{response[:result]}"
        details = parse_unprovisioned_onus(response[:result])
        onu_detail = nil

        details.each do |detail|
          Rails.logger.debug "Comparing #{detail[:sernum]} with #{sernum}"
          if detail[:sernum] == sernum
            onu_detail = detail
            Rails.logger.info "ONU is unprovisioned: #{detail.inspect}"
            break
          end
        end

        if onu_detail
          Rails.logger.info "ONU found and is unprovisioned."
          return { success: true, message: "ONU is unprovisioned.", details: onu_detail, status: :unprovisioned }
        else
          Rails.logger.warn "No unprovisioned ONU matched the serial number: #{sernum}"
          return { success: true, message: "ONU is provisioned.", status: :provisioned }
        end
      else
        Rails.logger.error "Failed to execute command: #{command}, Error: #{response[:error]}"
        return { success: false, error: "Failed to fetch unprovisioned ONU list.", status: :error }
      end
    end

    def parse_unprovisioned_onus(response)
      parsed_data = []
      lines = response.split("\n").map(&:strip)

      lines.reject! do |line|
        line.empty? || line.match?(/^-+$/) || !line.match?(/\d+/)  
      end

      regex_pattern = /(\d+)\s+(\d+\/\d+\/\d+\/\d+)\s+([A-Z0-9]+)\s+DEFAULT\s+([\d\.]+g)/

      lines.each do |line|
        Rails.logger.debug "Processing line: #{line}"
        match = regex_pattern.match(line)
        if match
          parsed_data << {
            alarm_idx: match[1].strip,
            gpon_index: match[2].strip,
            sernum: match[3].strip,
            subscriber_locid: "DEFAULT",
            logical_authid: "1.25g", 
            us_rate: match[4].strip,
          }
          Rails.logger.debug "Matched data: #{parsed_data.last.inspect}"
        else
          Rails.logger.debug "Line did not match expected format: #{line}"
        end
      end

      Rails.logger.info "Parsed unprovisioned ONUs: #{parsed_data}"
      parsed_data
    end

    def normalize_serial(serial)
      return nil if serial.nil?
      normalized = serial.gsub(/[^a-zA-Z0-9]/, "").upcase
      Rails.logger.debug "Normalized serial number from #{serial} to #{normalized}"
      normalized
    end

    def check_onu_position(ip, slot, pon, expected_serial)
      gpon_index = format("1/1/%s/%s", slot, pon)
      command = "show equipment ont status pon #{gpon_index}"
      response = post_olt_command(ip, command)

      Rails.logger.debug "Command response for #{gpon_index}: #{response.inspect}"

      if response[:success]
        ont_ports = parse_ont_ports(response[:result])
        if ont_ports[:success]
          normalized_expected_serial = expected_serial.gsub(/[^a-zA-Z0-9]/, "").upcase
          matched_onu = ont_ports[:data].find do |onu|
            onu_serial = onu[:sernum].gsub(/[^a-zA-Z0-9]/, "").upcase
            onu[:ont_index].start_with?(gpon_index) && onu_serial == normalized_expected_serial
          end

          if matched_onu
            Rails.logger.info "Matched ONU: #{matched_onu.inspect}"
            { success: true, message: "ONU found and serial matches", details: matched_onu }
          else
            Rails.logger.warn "No matching ONU found for serial #{normalized_expected_serial} at #{gpon_index}"
            { success: false, error: "No matching ONU found or serial mismatch" }
          end
        else
          Rails.logger.error "Failed to parse ONT ports: #{ont_ports[:error]}"
          ont_ports
        end
      else
        Rails.logger.error "Failed to execute command: #{command}, Error: #{response[:error]}"
        response
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

    def fetch_power(ip, ont_index)
      command = "show equipment ont optics #{ont_index}"
      response = post_olt_command(ip, command)

      if response[:success]
        regex_pattern = /#{Regexp.escape(ont_index)}\s+(?<rx_signal_level>-?\d+\.\d+|\bunknown\b)/
        match_data = response[:result].match(regex_pattern)

        if match_data && match_data[:rx_signal_level]
          rx_signal_level = match_data[:rx_signal_level]
          if rx_signal_level.downcase == "unknown"
            rx_signal_level = "Down"
          else
            rx_signal_level = rx_signal_level.to_f
          end
          { success: true, rx_signal_level: rx_signal_level }
        else
          { success: false, message: "Não foi possível extrair o rx_signal_level corretamente do resultado." }
        end
      else
        { success: false, error: "Falha ao buscar a potência da ONU: #{response[:error]}" }
      end
    end

    def post_olt_command(ip, command)
      olt_command_service = OltServices::OltCommandService.new
      response = olt_command_service.execute_command(ip, command)

      if response[:result].nil?
        return { success: false, error: "Command response is empty." }
      elsif response[:result].include?("Error :")
        error_message = response[:result].match(/Error : (.+)/)[1].strip
        return { success: false, error: error_message }
      else
        return { success: true, result: response[:result] }
      end
    end
  end
end
