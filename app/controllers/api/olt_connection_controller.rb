
module Api
class OltConnectionController < ApplicationController
    def equipment_ip
        access_point_id = params[:id]

        ip_address = AuthenticationIp
          .joins(:authentication_access_points)
          .where(authentication_access_points: { id: access_point_id })
          .pluck(:ip)
          .first

        if ip_address
           render json: { ip: ip_address}
        else
          render json: { error: "Nenhum IP encontrado para o título do access point #{access_point_title}." }, status: :not_found
        end
    end

    def equipment_ip_by_title
        olts_title = params[:olts]

        ip_address = AuthenticationIp
          .joins(:authentication_access_points)
          .where(authentication_access_points: { id: access_point_id })
          .pluck(:ip)
          .first

        if ip_address
           render json: { ip: ip_address}
        else
          render json: { error: "Nenhum IP encontrado para o título do access point #{access_point_title}." }, status: :not_found
        end
    end
end
end