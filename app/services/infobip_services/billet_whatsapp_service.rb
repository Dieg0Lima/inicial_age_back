require "rest-client"
require "json"

module InfobipServices
  class BilletWhatsappService
    def send_billet_message(to, placeholder, public_url)
      url = "https://j36lvj.api-us.infobip.com/whatsapp/1/message/template"
      headers = {
        "Content-Type" => "application/json",
        "Authorization" => "App #{ENV["INFOBIP_API_KEY"]}",
      }

      message_data = {
        "messages": [
          {
            "from": "5561920026666",
            "to": to,
            "content": {
              "templateName": "mensagem_teste",
              "templateData": {
                "body": {
                  "placeholders": [placeholder],
                },
                "header": {
                  "type": "DOCUMENT",
                  "mediaUrl": public_url,
                  "filename": "boleto.pdf",
                },
              },
              "language": "pt_BR",
            },
          },
        ],
      }

      response = RestClient.post(url, message_data.to_json, headers)

      JSON.parse(response.body)
    rescue RestClient::ExceptionWithResponse => e
      puts "Error sending billet message: #{e.response}"
      nil
    end
  end
end
