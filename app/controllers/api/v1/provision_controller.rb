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

      def provision
        provision_service = AttendantActions::ProvisionService.new

        provision = provision_service.provision

        if provision.present?
          render json: provision
        else
          render json: { error: "Não foi possível provisionar." }, status: :error
        end
      end
    end
  end
end
