require 'rails_helper'

RSpec.describe "Auths", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/auth/create"
      expect(response).to have_http_status(:success)
    end
  end

end
