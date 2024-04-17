module OltServices
  require "net/telnet"
  require "json"
  require "csv"

  class OltCommandService
    def execute_command(ip, command)

      olt_username = ENV["OLT_USERNAME"]
      olt_password = ENV["OLT_PASSWORD"]

      olt_host = ip
      olt_username = "#{olt_username}"
      olt_password = "#{olt_password}"
      command_to_execute = command

      begin
        telnet = Net::Telnet.new(
          "Host" => olt_host,
          "Timeout" => 180,
          "Prompt" => /[$%#>] \z/n,
        )

        telnet.login(olt_username, olt_password)
        puts "Telnet connection established."

        result = telnet.cmd(command_to_execute)

        result.gsub!("*", "")
        result.squeeze!(" ")

        puts result

        telnet.close

        { success: true, result: result }
      rescue StandardError => e
        puts "Error: #{e.message}"
        { success: false, error: e.message }
      end
    end
  end
end
