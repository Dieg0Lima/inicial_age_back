require 'rest-client'
require 'tempfile'

module BilletServices
  class GetBilletService
    def initialize(billet_id)
      @api_base_url = "https://erp.agetelecom.com.br:45715/external/integrations/thirdparty/GetBillet/#{billet_id}"
    end

    def get_billet_stream
      VoalleAuthenticationService.fetch_access_token if APIAuthenticationService.access_token.nil?
      access_token = APIAuthenticationService.access_token
      response = RestClient::Request.execute(
        method: :get,
        url: @api_base_url,
        headers: { Authorization: "Bearer #{access_token}", accept: :pdf },
        raw_response: true,
      )

      Tempfile.open(['billet', '.pdf']) do |file|
        file.binmode
        file.write(response.body)
        file.rewind
        yield(file)
      end
    rescue RestClient::ExceptionWithResponse => e
      e.response
    end
  end
end
