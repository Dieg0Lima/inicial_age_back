module Api
  module V1
    class SendBilletController < ApplicationController
      include Authenticatable

      def whatsapp
        billet_id = params[:billet_id]
        to = normalize_phone_number(params[:to])
        placeholder = params[:client]

        unless valid_phone_number?(to)
          render json: { error: "Número de telefone inválido" }, status: :bad_request
          return
        end

        billet_service = BilletServices::GetBilletService.new(billet_id)

        begin
          billet_service.get_billet_stream do |pdf_stream|
            uploader_service = AwsServices::S3UploaderBilletService.new
            public_url = uploader_service.upload_from_stream(pdf_stream)

            infobip_service = InfobipServices::BilletWhatsappService.new
            response = infobip_service.send_billet_message(to, placeholder, public_url)

            if response && response["messages"][0]["status"]["groupName"] == "PENDING"
              render json: { media_url: public_url, message: "Fatura enviada com sucesso para o WhatsApp" }, status: :ok
            else
              render json: { error: "Erro ao enviar fatura para o WhatsApp" }, status: :internal_server_error
            end
          end
        rescue StandardError => e
          render json: { error: e.message }, status: :internal_server_error
        end
      end

      private

      def normalize_phone_number(phone_number)
        normalized_number = phone_number.gsub(/\s+|\D+/, "")
        normalized_number = "55#{normalized_number}" unless normalized_number.start_with?("55")
        normalized_number.insert(4, "9") unless normalized_number[4] == "9"
        normalized_number
      end

      def valid_phone_number?(phone_number)
        phone_number = phone_number.gsub(/\D/, "")
        return false unless phone_number.match?(/^55\d{11}$/)
        ddd = phone_number.match(/(?<=55)\d{2}/)[0].to_i
        valid_ddd?(ddd)
      end

      def valid_ddd?(ddd)
        valid_ddds = [11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 24, 27, 28, 31, 32, 33, 34, 35, 37, 38, 41, 42, 43, 44, 45, 46, 47, 48, 49, 51, 53, 54, 55, 61, 62, 63, 64, 65, 66, 67, 68, 69, 71, 73, 74, 75, 77, 79, 81, 82, 83, 84, 85, 86, 87, 88, 89, 91, 92, 93, 94, 95, 96, 97, 98, 99]
        valid_ddds.include?(ddd)
      end
    end
  end
end
