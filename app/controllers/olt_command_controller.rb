require 'net/telnet'
require 'json'
require 'csv'

class OltCommandController < ApplicationController
  def execute_command
    olt_host = params[:ip]
    olt_username = 'isadmin'
    olt_password = 'age@isadmin'
    command_to_execute = params[:command]

    begin
      telnet = Net::Telnet.new(
        'Host' => olt_host,
        'Timeout' => 180,
        'Prompt' => /[$%#>] \z/n
      )

      telnet.login(olt_username, olt_password)
      puts "Telnet connection established."

      result = telnet.cmd(command_to_execute)
      puts result

      telnet.close

      render json: { success: true, result: result }
    rescue StandardError => e
      puts "Error: #{e.message}"
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end
  end
end
