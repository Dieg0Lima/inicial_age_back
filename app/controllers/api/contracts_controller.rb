module Api
  class ContractsController < ApplicationController
    def index
      client_name = contract_params[:client_name]
      contracts = Contract.custom_query(client_name, page: params[:page], per_page: params[:per_page])
      render json: contracts
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end

    def show
          contract = Contract.find(params[:id])
          render json: contract
    end

    private

    def contract_params
      params.permit(:client_name)
    end
  end
end
