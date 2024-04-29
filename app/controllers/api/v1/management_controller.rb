module Api
  module V1
    class ManagementController < ApplicationController
      include Authenticatable

      before_action :set_management_service

      def management_onu
        sernum = params[:sernum]

        result = @management_service.management_onu(sernum)

        if result[:success]
          render json: {
            success: true,
            message: "Gerenciamento com Sucesso",
            ip: result[:ip] 
          }, status: :ok
        else
          render json: {
            success: false,
            error: result[:error]
          }, status: :unprocessable_entity
        end
      end

      private

      def set_management_service
        @management_service = AttendantActions::ManagementService.new
      end
    end
  end
end
