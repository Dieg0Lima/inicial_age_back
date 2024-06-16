module Api
    class ConnectionIntegrationVoalleController < ApplicationController
      def get_id
        contract = params[:contract]

        begin
          get_id = AuthenticationContract
                      .select(:id, :equipment_serial_number, :activation_date, :modified)
                      .where("CAST(contract_id AS TEXT) LIKE ?", "%#{contract}%")
                      .order(created: :desc)

          if get_id.present?
            render json: get_id.as_json
          else
            render json: { error: "Nenhum id de Contrato encontrado." }, status: :not_found
          end
        rescue => e
          render json: { error: e.message }, status: :internal_server_error
        end
      end
    end
end
