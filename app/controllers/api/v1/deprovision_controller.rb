module Api
  module V1
    class DeprovisionController < ApplicationController
      include Authenticatable

      before_action :set_deprovision_service

      def deprovision_onu
        olt_id = params[:olt_id]
        sernum = params[:sernum]
        slot = params[:slot]
        pon = params[:pon]
        port = params[:port]
        user_id = @current_user[:id]

        gpon_index = "1/1/#{slot}/#{pon}/#{port}"

        result = @deprovision_service.deprovision_onu(olt_id, gpon_index, sernum, user_id)

        if result[:success]
          render json: { message: "ONU Deprovisioned Successfully" }, status: :ok
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end

      private

      def set_deprovision_service
        @deprovision_service = AttendantActions::DeprovisionService.new
      end
    end
  end
end
