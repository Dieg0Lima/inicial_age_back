module B1SlayerIntegration
  require "net/http"
  require "json"

  B1_API_BASE_URL = "https://saphaage.skyinone.net:50000"

  def self.authenticate(username, password, company_db)
    uri = URI("#{B1_API_BASE_URL}/b1s/v1/Login")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" })
    request.body = { UserName: username, Password: password, CompanyDB: company_db }.to_json

    response = http.request(request)
    if response.is_a?(Net::HTTPSuccess)
      { cookies: response.get_fields("set-cookie"), body: JSON.parse(response.body) }
    else
      { error: response.message, code: response.code, body: JSON.parse(response.body) }
    end
  end

  def self.create_business_partner(business_partner_data, cookies)
    uri = URI("#{B1_API_BASE_URL}/b1s/v1/BusinessPartners")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" })
    request.body = business_partner_data.to_json
    request["Cookie"] = cookies

    response = http.request(request)
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      { error: response.message, code: response.code, body: JSON.parse(response.body) }
    end
  end

  def self.create_item(item_data, cookies)
    uri = URI("#{B1_API_BASE_URL}/b1s/v1/Items")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" })
    request.body = item_data.to_json
    request["Cookie"] = cookies

    response = http.request(request)
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      { error: response.message, code: response.code, body: JSON.parse(response.body) }
    end
  end

  def self.create_invoice(invoice_data, cookies)
    uri = URI("#{B1_API_BASE_URL}/b1s/v1/Invoices")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" })
    request.body = invoice_data.to_json
    request["Cookie"] = cookies

    response = http.request(request)
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      { error: response.message, code: response.code, body: JSON.parse(response.body) }
    end
  end
end
