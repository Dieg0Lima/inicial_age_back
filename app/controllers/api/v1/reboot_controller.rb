module Api
  module V1
    class RebootController < ApplicationController
      include Authenticatable

      before_action :set_reboot_service

      def reboot_onu
        olt_id = params[:olt_id]
        sernum = params[:sernum]
        slot = params[:slot]
        pon = params[:pon]
        port = params[:port]
        user_id = @current_user[:id]

        result = @reboot_service.reboot_onu(olt_id, slot, pon, port, sernum, user_id)

        if result[:success]
          render json: { success: true, message: "ONU Rebooted Successfully" }, status: :ok
        else
          render json: { success: false, error: result[:error] }, status: :unprocessable_entity
        end
      end

      private

      def set_reboot_service
        @reboot_service = AttendantActions::RebootService.new
      end
    end
  end
end
