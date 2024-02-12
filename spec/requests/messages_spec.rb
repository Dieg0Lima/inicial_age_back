require 'rails_helper'

RSpec.describe "Messages", type: :request do
  describe "GET /send" do
    it "returns http success" do
      get "/messages/send"
      expect(response).to have_http_status(:success)
    end
  end

end
