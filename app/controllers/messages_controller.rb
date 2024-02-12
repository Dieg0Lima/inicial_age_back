class MessagesController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'json'
  require 'securerandom'

  def send_message
    begin
      data = {
          id: SecureRandom.uuid,
          to: "+5561991659351@sms.gw.msging.net",
          type: "text/plain",
          content: "Boa Tarde, segue um modelo para teste.\nAGE Telecom: Sua fatura já está disponível. Acesse através do portal da AGE: https://encr.pw/qv4Ed\n\n Se já pagou, desconsidere."
      }

      uri = URI.parse("https://agetelecom.http.msging.net/messages")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      headers = {
          "Content-Type" => "application/json",
          "Authorization" => "Key cm90ZWFkb3JzbXMxOk5uWHNINVJvTjNMejlBQmxOVG95"
      }

      response = http.post(uri.path, data.to_json, headers)

      render json: { status: "success", message: "Mensagem enviada com sucesso." }
    rescue => e
      render json: { status: "error", message: "Erro ao enviar a mensagem: #{e.message}" }, status: :internal_server_error
    end
  end
end
