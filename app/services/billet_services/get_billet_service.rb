require 'rest-client'
require 'json'

module BilletServices
  class GetBilletService
    include Authenticatable

    def initialize
      @api_base_url = "https://erp.agetelecom.com.br:45715/external/integrations/thirdparty/GetBillet/5541623"
    end

    def get_billet()
      access_token = APIAuthentication.access_token
      response = RestClient.get "#{@api_base_url}",
                                { Authorization: "Bearer #{access_token}",
                                  content_type: :json, accept: :json }

      JSON.parse(response.body)
    rescue RestClient::ExceptionWithResponse => e
      e.response
    end
  end
end
