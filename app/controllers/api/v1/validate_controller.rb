module Api
  module V1
    class ValidateController < ApplicationController
      include Authenticatable

      before_action :set_validate_cto_service

      def validate_cto
        cto = params[:cto]

        result = @validate_cto_service.validate_cto(cto)

        if result[:success]
          if result[:data]
            render json: { success: true, message: "CTO validated successfully", isValid: true, data: result[:data] }, status: :ok
          else
            render json: { success: false, message: "CTO not found", isValid: false }, status: :unprocessable_entity
          end
        else
          render json: { success: false, error: result[:error], isValid: false }, status: :unprocessable_entity
        end
      end

      private

      def set_validate_cto_service
        @validate_cto_service = AttendantActions::ValidateCtoService
      end
    end
  end
end
