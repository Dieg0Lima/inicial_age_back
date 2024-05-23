module Api
require 'net/telnet'
require 'json'
require 'csv'

class OltController < ApplicationController
  def execute_command
    olt_host = params[:ip]
    olt_username = 'isadmin'
    olt_password = 'age@isadmin'
    command_to_execute = params[:command]
    max_attempts = 3

    attempt = 0
    begin
      attempt += 1
      telnet = Net::Telnet.new(
        'Host' => olt_host,
        'Timeout' => 120,
        'Prompt' => /[$%#>] \z/n
      )

      puts "Tentando conectar... Tentativa #{attempt}"
      telnet.login(olt_username, olt_password)
      puts "Conexão Telnet estabelecida."

      result = telnet.cmd(command_to_execute)
      puts result

      telnet.close

      render json: { success: true, result: result }
    rescue StandardError => e
      puts "Erro: #{e.message}. Tentando novamente..."

      if attempt < max_attempts
        sleep 5
        retry
      else
        puts "Falha após #{max_attempts} tentativas."
        render json: { success: false, error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
end