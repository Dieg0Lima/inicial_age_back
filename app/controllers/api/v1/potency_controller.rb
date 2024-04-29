module Api
  module V1
    class PotencyController < ApplicationController
      include Authenticatable

      before_action :set_potency_service

      def fetch_onu_power
        olt_id = params[:olt_id]
        sernum = params[:sernum]
        slot = params[:slot]
        pon = params[:pon]
        port = params[:port]

        result = @potency_service.fetch_onu_power(olt_id, slot, pon, port, sernum)

        if result[:success]
          render json: { success: true, rx_signal_level: result[:power], message: "ONU power level retrieved successfully" }, status: :ok
        else
          render json: { success: false, message: result[:error] }, status: :unprocessable_entity
        end
      end

      private

      def set_potency_service
        @potency_service = AttendantActions::PotencyService.new
      end
    end
  end
end
