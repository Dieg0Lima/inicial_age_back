require "net/http"
require "uri"
require "digest/md5"

module IntelbrasServices
  class OpenDoorService
    def initialize(ip, username, password)
      @ip = ip
      @username = username
      @password = password
    end

    def open_door
      url = URI.parse("http://#{@ip}/cgi-bin/accessControl.cgi?action=openDoor&channel=1")
      http = Net::HTTP.new(url.host, url.port)

      request = Net::HTTP::Get.new(url.request_uri)
      response = http.request(request)

      if response["www-authenticate"]
        auth_params = parse_www_authenticate(response["www-authenticate"])

        ha1 = Digest::MD5.hexdigest("#{@username}:#{auth_params["realm"]}:#{@password}")
        ha2 = Digest::MD5.hexdigest("GET:#{url.path}")
        nonce_count = "00000001"
        cnonce = "0a4f113b" 
        qop = auth_params["qop"]
        response_digest = Digest::MD5.hexdigest("#{ha1}:#{auth_params["nonce"]}:#{nonce_count}:#{cnonce}:#{qop}:#{ha2}")

        auth_header = create_auth_header(url, @username, auth_params["realm"], auth_params["nonce"], response_digest, nonce_count, cnonce, qop)

        request = Net::HTTP::Get.new(url.request_uri)
        request["Authorization"] = auth_header

        final_response = http.request(request)

        if final_response.code.to_i == 200
          puts "Response body: #{final_response.body}"
          JSON.parse(final_response.body)
        else
          puts "Failed to authenticate: #{final_response.code}"
          { error: "Failed to authenticate", status: final_response.code }
        end
      else
        puts "No WWW-Authenticate header found"
        { error: "No WWW-Authenticate header found" }
      end
    rescue => e
      puts "An error occurred: #{e.message}"
      { error: "An unexpected error occurred", details: e.message }
    end

    private

    def parse_www_authenticate(header)
      header.gsub("Digest ", "").split(", ").map { |param| param.split("=") }.to_h { |key, value| [key, value.gsub('"', "")] }
    end

    def create_auth_header(url, user, realm, nonce, response, nonce_count, cnonce, qop)
      "Digest username=\"#{user}\", realm=\"#{realm}\", nonce=\"#{nonce}\", uri=\"#{url.path}\", response=\"#{response}\", " \
      "nc=#{nonce_count}, cnonce=\"#{cnonce}\", qop=#{qop}, algorithm=MD5"
    end
  end
end
