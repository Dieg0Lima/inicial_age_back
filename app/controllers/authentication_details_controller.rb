class AuthenticationDetailsController < ApplicationController
  def authentication_details
    equipment_serial = params[:equipment_serial_number]

    results = AuthenticationContract
        .joins(:authentication_access_point, :authentication_address_list, :service_product)
        .where(equipment_serial_number: equipment_serial)
        .select(
            'authentication_contracts.port_olt AS pon',
            'authentication_contracts.equipment_serial_number AS equipment',
            'authentication_contracts.slot_olt AS slot',
            'authentication_access_points.title AS POP',
            'authentication_contracts.wifi_name AS SSID',
            'authentication_contracts.wifi_password AS password',
            'authentication_contracts.olt_id AS olt_id',
            'authentication_address_lists.title AS status',
            'service_products.title AS product'
        )
        .map(&:attributes)

    if results.any?
      render json: results
    else
      render json: { error: "Nenhuma informação encontrada para o número de série do equipamento #{equipment_serial}." }, status: :not_found
    end
  end
end
