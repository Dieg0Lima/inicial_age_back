class OltTitleController < ApplicationController
  def find_id_by_serial
    equipment_serial = params[:equipment_serial_number]

    olt_id = AuthenticationContract
      .joins(:authentication_access_point)
      .where(equipment_serial_number: equipment_serial)
      .pluck('authentication_access_points.id')
      .first

    if olt_id
      render json: { olt_id: olt_id }
    else
      render json: { error: "Nenhum título de OLT encontrado para o número de série do equipamento #{equipment_serial}." }, status: :not_found
    end
  end
end
