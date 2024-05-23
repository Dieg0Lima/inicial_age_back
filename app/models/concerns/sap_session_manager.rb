module SapSessionManager
  extend ActiveSupport::Concern

  included do
    attr_reader :sap_session_id
  end

  def ensure_sap_session
    renew_sap_session unless sap_session_valid?
  end

  private

  def sap_session_valid?
    sap_session_id.present? && sap_session_last_renewed_at > Time.current - 12.hours
  end

  def renew_sap_session
    response = HTTParty.post("#{ENV["B1_API_URL"]}/Login",
                             body: login_details,
                             headers: { "Content-Type" => "application/json" })
    if response.success?
      set_sap_session(response.headers["set-cookie"])
    else
      raise StandardError.new("Failed to login to SAP: #{response.body}")
    end
  end

  def set_sap_session(cookie)
    @sap_session_id = cookie[/B1SESSION=(.+?);/, 1]
    self.sap_session_last_renewed_at = Time.current
  end

  def login_details
    {
      "UserName" => ENV["B1_USERNAME"],
      "Password" => ENV["B1_PASSWORD"],
      "CompanyDB" => ENV["B1_COMPANYDB"],
    }.to_json
  end
end
