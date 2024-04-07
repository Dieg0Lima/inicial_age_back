module Api
  module V1
    class SearchClientController < ApplicationController
      include Authenticatable

      def search
        value = params[:value]

        render json: { error: "A search value must be provided" }, status: :bad_request and return unless value.present?

        results = perform_search(value)
        if results.any?
          render json: { results: results.as_json }, status: :ok
        else
          render json: { message: "No results found" }, status: :not_found
        end
      end

      private

      def perform_search(value)
        search_service = SearchClientService.new(value)
        search_service.search
      end

    end
  end
end
