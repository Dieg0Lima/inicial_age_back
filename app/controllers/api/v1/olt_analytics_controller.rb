module Api
  module V1
    class OltAnalyticsController < ApplicationController
      include Authenticatable

      def download_xlsx
        result = OltAnalytics::OltAnalyticsService.fetch_data_to_xlsx

        if result[:success]
          send_file result[:file_path], type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", disposition: "attachment", filename: File.basename(result[:file_path])
        else
          render json: { error: result[:error] }, status: :internal_server_error
        end
      end
    end
  end
end
