require "rails_helper"

RSpec.describe BusinessPartnersController, type: :controller do
  describe "POST #create" do
    let(:business_partner_params) { { CardName: "Teste API", CardType: "C", GroupCode: 100 } }

    it "creates a business partner and sends it to B1Slayer" do
      post :create, params: { business_partner: business_partner_params }
      expect(response).to have_http_status(:created)
    end
  end
end
