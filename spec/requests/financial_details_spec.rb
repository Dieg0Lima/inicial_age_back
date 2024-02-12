require 'rails_helper'

RSpec.describe "FinancialDetails", type: :request do
  describe "GET /financial_info" do
    it "returns http success" do
      get "/financial_details/financial_info"
      expect(response).to have_http_status(:success)
    end
  end

end
