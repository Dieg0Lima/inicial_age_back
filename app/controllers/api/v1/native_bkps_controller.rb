module Api
  module V1
    class NativeBkpsController < ApplicationController
      def index
        Rails.logger.info("Iniciando a consulta de NativeBkp")
        begin
          @native_bkps = NativeBkp.all
          Rails.logger.info("Consulta de NativeBkp concluída com #{@native_bkps.size} registros")
          render json: @native_bkps
        rescue => e
          Rails.logger.error("Erro na consulta de NativeBkp: #{e.message}")
          render json: { error: "Erro na consulta de NativeBkp" }, status: :internal_server_error
        end
      end
    end
  end
end
