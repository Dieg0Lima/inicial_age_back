module B1SlayerAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_with_b1_slayer
  end

  private

  def authenticate_with_b1_slayer
    username = ENV["B1_USERNAME"]
    password = ENV["B1_PASSWORD"]
    company_db = ENV["B1_COMPANYDB"]

    response = B1SlayerIntegration.authenticate(username, password, company_db)
    if response[:error]
      render json: { error: response[:error] }, status: :unauthorized
    else
      @b1_cookies = response[:cookies].map { |cookie| cookie.split("; ")[0] }.join("; ")
    end
  end

  def b1_cookies
    @b1_cookies
  end
end
