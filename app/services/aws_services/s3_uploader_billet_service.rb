require "aws-sdk-s3"

module AwsServices
  class S3UploaderBilletService
    def initialize(bucket_name = "age-atende")
      @bucket_name = bucket_name
      @s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"])
    end

    def upload_from_stream(pdf_stream)
      filename = "boletos/#{SecureRandom.uuid}.pdf"
      obj = @s3.bucket(@bucket_name).object(filename)

      pdf_content = pdf_stream.read

      obj.put(body: pdf_content, acl: "public-read", content_type: "application/pdf")

      obj.public_url
    rescue Aws::S3::Errors::ServiceError => e
      raise e
    end
  end
end
