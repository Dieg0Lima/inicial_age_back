require "aws-sdk-s3"

module AwsServices
  class NativeRecordService
    def initialize(bucket_name = "bsa.age.bkp.native")
      @bucket_name = bucket_name
      @s3_client = Aws::S3::Client.new(region: ENV["AWS_REGION"])
    end

    def list_files_with_urls(year, month, day)
      prefix = "gravacoes/#{year}/#{month.to_s.rjust(2, '0')}/#{day.to_s.rjust(2, '0')}/"
      files_with_urls = []

      response = @s3_client.list_objects_v2(
        bucket: @bucket_name,
        prefix: prefix
      )

      response.contents.each do |obj|
        files_with_urls << { key: obj.key, url: generate_public_url(obj.key) }
      end

      { files: files_with_urls }
    rescue Aws::S3::Errors::ServiceError => e
      raise e
    end

    private

    def generate_public_url(key)
      "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{key}"
    end
  end
end
