module Api
  module V1
    class ConnectionDetailsController < ApplicationController
      include Authenticatable

      def show
        client_service = ConnectionDetails::ClientService.new
        client = client_service.fetch_client_data(params[:id])
        unless client
          render json: { error: "Client not found" }, status: :not_found
          return
        end

        contract_service = ConnectionDetails::ContractService.new
        contract = contract_service.fetch_contract_data(params[:id])
        unless contract
          render json: { error: "Contract not found" }, status: :not_found
          return
        end

        connection_service = ConnectionDetails::ConnectionService.new
        connection = connection_service.fetch_connection_data(params[:id])
        unless connection
          render json: { error: "Connection not found" }, status: :not_found
          return
        end

        financial_service = ConnectionDetails::FinancialService.new
        financial = financial_service.fetch_financial_data(params[:id])
        unless financial
          render json: { error: "Financial not found" }, status: :not_found
          return
        end

        assignment_service = ConnectionDetails::AssignmentService.new
        assignment = assignment_service.fetch_assignment_data(params[:id])
        unless assignment
          render json: { error: "Assignment not found" }, status: :not_found
          return
        end

        render json: { client: client, contract: contract, connection: connection, financial: financial, assignment: assignment }
      end
    end
  end
end
