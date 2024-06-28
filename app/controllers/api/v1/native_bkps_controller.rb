require "aws-sdk-s3"

module Api
  module V1
    class NativeBkpsController < ApplicationController
      def search
        if search_params[:src].present? || search_params[:start].present?
          begin
            start_date = Date.parse(search_params[:start]) if search_params[:start].present?

            records = NativeBkp.all
            records = records.where("start >= ?", start_date) if start_date.present?
            records = records.where(disposition: 'ANSWERED')
                             .where(lastapp: 'Dial')
            records = records.where(src: search_params[:src]) if search_params[:src].present?
            records = records.where(dst: search_params[:dst]) if search_params[:dst].present?

            metadata_map = records.each_with_object({}) do |record, hash|
              hash[record.uniqueid] = filter_metadata(record)
            end

            unique_ids = metadata_map.keys
            dates_to_search = records.pluck(:start).map { |date| date.to_date }.uniq
            files_with_metadata = []
            total_objects = 0

            service = AwsServices::NativeRecordService.new

            dates_to_search.each do |date|
              year, month, day = date.year, date.month, date.day
              result = service.list_files_with_urls(year, month, day)

              result[:files].each do |file|
                unique_ids.each do |uniqueid|
                  if file_contains_uniqueid?(file[:key], uniqueid)
                    filtered_metadata = metadata_map[uniqueid]

                    files_with_metadata << {
                      uniqueid: uniqueid,
                      url: file[:url],
                      start: filtered_metadata[:start],
                      dst: filtered_metadata[:dst],
                      clid: filtered_metadata[:clid],
                      trunkusername: filtered_metadata[:trunkusername],
                      direction: filtered_metadata[:direction],
                      src: filtered_metadata[:src]
                    }
                  end
                end
              end

              total_objects += result[:files].size
            end

            Rails.logger.info("Total files with metadata: #{files_with_metadata.size}")
            Rails.logger.info("Total objects found: #{total_objects}")

            render json: { files: files_with_metadata.uniq { |f| f[:uniqueid] }, total_objects: total_objects }, status: :ok
          rescue ArgumentError => e
            render json: { error: "Invalid date format" }, status: :bad_request
          rescue => e
            render json: { error: e.message }, status: :internal_server_error
          end
        else
          render json: { error: "At least one of the parameters (start, src) must be present" }, status: :bad_request
        end
      end

      private

      def search_params
        params.permit(:start, :src, :dst)
      end

      def filter_metadata(metadata)
        metadata.slice(:uniqueid, :start, :dst, :clid, :trunkusername, :direction, :src)
      end

      def file_contains_uniqueid?(key, uniqueid)
        extracted_uniqueid = extract_uniqueid(key)
        extracted_uniqueid == uniqueid
      end

      def extract_uniqueid(key)
        key[/call-(\d+\.\d+)\.mp3$/, 1]
      end
    end
  end
end
