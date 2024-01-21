module Api
  class ContractsController < ApplicationController
    def show
        contract_number = params[:contract_number]
        contract = Contract.where(contract_number: contract_number).pluck(:contract_number).first

        if contract
          render json: { contract_number: contract }
        else
          render json: { error: "Contrato não encontrado." }, status: :not_found
        end
      end
  end
end
