require 'rails_helper'

RSpec.describe "AuthenticationDetails", type: :request do
  describe "GET /authentication_details" do
    it "returns http success" do
      get "/authentication_details/authentication_details"
      expect(response).to have_http_status(:success)
    end
  end

end
