require 'rest-client'
require 'json'

module VoalleAuthenticationService
  class << self
    attr_accessor :access_token

    def fetch_access_token
      payload = {
        client_id: ENV['CLIENT_ID_VOALLE'],
        client_secret: ENV['CLIENT_SECRET_VOALLE'],
        syndata: ENV['SYNDATA_VOALLE'],
        grant_type: 'client_credentials',
        scope: 'syngw'
      }

      response = RestClient.post "https://erp.agetelecom.com.br:45700/connect/token",
                                 payload,
                                 { content_type: :urlencoded }

      result = JSON.parse(response.body)
      @access_token = result['access_token']
    end
  end
end
