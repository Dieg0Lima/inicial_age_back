module Api
  module V1
    class ProvisionController < ApplicationController
      before_action :set_provision_service
      include Authenticatable

      def list_valid_olts
        valid_olts = @provision_service.valid_olt_list
        if valid_olts.present?
          render json: valid_olts
        else
          render json: { error: "Nenhum título de OLT encontrado." }, status: :not_found
        end
      end

      def provision_onu
        olt_id = params[:olt_id]
        contract = params[:contract]
        sernum = params[:sernum]
        connection_id = params[:connection_id]
        user_id = @current_user[:id]
        cto = params[:cto]
        result = @provision_service.provision_onu(olt_id, contract, sernum, connection_id, user_id, cto)

        if result[:success]
          render json: { success: true, message: "ONU Provisioned Successfully" }, status: :ok
        else
          render json: { success: false, error: result[:error] }, status: :unprocessable_entity
        end
      end

      def fetch_olt_with_ip
        olt_id = params[:olt_id]
        ip_info = @provision_service.fetch_olt_with_ip(olt_id)
        if ip_info.present?
          render json: ip_info
        else
          render json: { error: "Não foi possível obter o IP da OLT." }, status: :not_found
        end
      end

      private

      def set_provision_service
        @provision_service = AttendantActions::ProvisionService.new
      end
    end
  end
end
