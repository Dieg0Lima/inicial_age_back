require 'rails_helper'

RSpec.describe "AttendantDetails", type: :request do
  describe "GET /attendat_details" do
    it "returns http success" do
      get "/attendant_details/attendat_details"
      expect(response).to have_http_status(:success)
    end
  end

end
