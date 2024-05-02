module AwsServices
  class S3UploaderBilletService
    def initialize(bucket_name = "age-atende")
      @bucket_name = bucket_name
      @s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"])
    end

    def upload(pdf_file)
      filename = "boletos/#{SecureRandom.uuid}.pdf"
      obj = @s3.bucket(@bucket_name).object(filename)

      obj.upload_file(pdf_file.path)

      obj.public_url
    end
  end
end
