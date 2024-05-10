module Api
  module V1
    module SendBillet
      class BilletsController < ApplicationController
        def show
          billet_service = BilletServices::GetBilletService.new

          pdf_data = billet_service.get_billet

          send_data pdf_data, filename: "billet.pdf", type: "application/pdf", disposition: "inline"
        rescue StandardError => e
          render json: { error: e.message }, status: :internal_server_error
        end
      end
    end
  end
end
