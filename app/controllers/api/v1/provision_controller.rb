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
      end
    end
  end
  