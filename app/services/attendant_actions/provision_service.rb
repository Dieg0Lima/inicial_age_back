require 'open3'

module AttendantActions
  class ProvisionService
    def initialize(olt_id, equipemt, ceo)
      @olt_id = olt_id 
      @equipemt = equipemt
      @ceo = ceo
    end

    def valid_olt_list
      AuthenticationAccessPoint.bsa_olts
    end

    def provision
      olt = fetch_olt_with_ip
      return { success: false, message: "OLT not found or IP not set" } unless olt && olt.authentication_ip

      username = ENV["OLT_USERNAME"]
      password = ENV["OLT_PASSWORD"]
      script_path = Rails.root.join("scripts", "olt_command_executor.py").to_s

      ip = olt.authentication_ip.ip
      command = "python3 #{script_path} #{ip.shellescape} #{username.shellescape} #{password.shellescape}"

      stdout, stderr, status = Open3.capture3(command)
      
      if status.success?
        { success: true, message: stdout.strip }
      else
        { success: false, message: stderr.strip }
      end
    end

    private

    def fetch_olt_with_ip
      AuthenticationAccessPoint.includes(:authentication_ip).find_by(id: @olt_id)
    end
  end
end
