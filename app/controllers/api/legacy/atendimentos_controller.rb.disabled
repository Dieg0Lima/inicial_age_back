module Api
    class AtendimentosController < ApplicationController
      def search
        if params[:contract_number]
          @results = perform_contract_search(params[:contract_number])
        elsif params[:cpf]
          @results = perform_cpf_search(params[:cpf])
        elsif params[:name]
          @results = perform_name_search(params[:name])
        else
          # Lógica padrão quando nenhum critério de pesquisa é fornecido
          @results = default_search_logic
        end
      end

      private

      def perform_contract_search(contract_number)
        contract = Contract.find_by(contract_number: contract_number)

        if contract
          client_name = contract.person.name
        else
          client_name = "Contrato não encontrado"
        end

        client_name
      end

      def perform_cpf_search(cpf)
        @results = Person.where(cpf: cpf)
      end

      def perform_name_search(name)
        @results = Person.where("name LIKE ?", "%#{name}%")
      end

      def default_search_logic
        # Lógica padrão quando nenhum critério de pesquisa é fornecido
      end
    end
end