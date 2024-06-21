module OltServices
  require "net/telnet"
  require "json"
  require "csv"
  require "logger"

  class OltCommandService
    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
    end

    def execute_command(ip, command)
      olt_username = ENV.fetch("OLT_USERNAME", "default_username")
      olt_password = ENV.fetch("OLT_PASSWORD", "default_password")

      telnet = nil
      begin
        telnet = establish_connection(ip, olt_username, olt_password)
        @logger.info("Telnet connection established.")

        result = execute_telnet_command(telnet, command)
        result = sanitize_result(result)
        
        puts "Comando: #{command}"
        puts "Resultado: #{result}"
        @logger.info("Command executed successfully.")
        { success: true, result: result }
      rescue StandardError => e
        @logger.error("Error executing command: #{e.message}")
        { success: false, error: e.message }
      ensure
        telnet&.close
        @logger.info("Telnet connection closed.") if telnet
      end
    end

    private

    def establish_connection(ip, username, password)
      Net::Telnet.new(
        "Host" => ip,
        "Timeout" => 180,
        "Prompt" => /[$%#>] \z/n,
      ).tap do |telnet|
        telnet.login(username, password)
      end
    end

    def execute_telnet_command(telnet, command)
      telnet.cmd(command)
    end

    def sanitize_result(result)
      result.gsub!("*", "")
      result.squeeze!(" ")
      result
    end
  end
end
