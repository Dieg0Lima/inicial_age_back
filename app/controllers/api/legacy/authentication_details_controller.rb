module Api
    class AuthenticationDetailsController < ApplicationController
      def authentication_details
        id = params[:connection]

        results = AuthenticationContract
            .left_joins(:authentication_access_point)
            .where(id: id)
            .select(
                'authentication_contracts.port_olt AS pon',
                'authentication_contracts.equipment_serial_number AS equipment',
                'authentication_contracts.slot_olt AS slot',
                'authentication_access_points.title AS POP',
                'authentication_contracts.wifi_name AS SSID',
                'authentication_contracts.wifi_password AS password',
                'authentication_contracts.olt_id AS olt_id',
                'authentication_contracts.id AS id',
                'authentication_access_points.id AS equipment_id'
            )
            .map(&:attributes)

        if results.any?
          render json: results
        else
          render json: { error: "Nenhuma informação encontrada para a conexão #{id}." }, status: :not_found
        end
      end
    end
end