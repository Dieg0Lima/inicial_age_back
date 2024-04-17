module Api
  module V1
    class ProvisionController < ApplicationController
      def list_valid_olts
        provision_service = AttendantActions::ProvisionService.new

        valid_olts = provision_service.valid_olt_list

        if valid_olts.present?
          render json: valid_olts
        else
          render json: { error: "Nenhum título de OLT encontrado." }, status: :not_found
        end
      end

      def provision_onu
        olt_id = params[:olt_id]
        slot = params[:slot]
        pon = params[:pon]
        port = params[:port]
        contract = params[:contract]
        sernum = params[:sernum]
        connection_id = params[:connection_id]

        result = AttendantActions::ProvisionService.new.provision_onu(olt_id, slot, pon, port, contract, sernum, connection_id)

        if result[:success]
          render json: { message: "ONU Provisioned Successfully" }, status: :ok
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end

      def fetch_olt_with_ip
        provision_service = AttendantActions::ProvisionService.new

        fetch_ip = provision_service.fetch_olt_with_ip

        if fetch_ip.present?
          render json: fetch_ip
        else
          render json: { error: "Não foi possível provisionar." }, status: :error
        end
      end
    end
  end
end
