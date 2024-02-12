require 'rails_helper'

RSpec.describe AuthenticationController, type: :controller do
  describe 'POST #login' do
    let(:username) { 'diego.lima' }
    let(:password) { 'TanyaDegurechaff69.' }

    context 'when credentials are valid' do
      before do
        allow_any_instance_of(LdapService).to receive(:authenticate).with(username, password).and_return(true)
        post :login, params: { username: username, password: password }
      end

      it 'returns a status code of 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns a JWT token in the response' do
        expect(JSON.parse(response.body)).to include('token')
      end
    end

    context 'when credentials are invalid' do
      before do
        allow_any_instance_of(LdapService).to receive(:authenticate).with(username, password).and_return(false)
        post :login, params: { username: username, password: password }
      end

      it 'returns a status code of 401' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error message' do
        expect(JSON.parse(response.body)).to include('error' => 'Credenciais inválidas')
      end
    end
  end
end
