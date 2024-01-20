require 'rails_helper'

RSpec.describe Api::ContractsController, type: :controller do
  describe 'GET #index' do
    context 'quando não há filtros' do
      it 'retorna todos os contratos' do
        get :index
        expect(response).to be_successful
        expect(response).to have_http_status(200)
      end
    end

    context 'com filtro de nome do cliente' do
      it 'retorna contratos filtrados' do
        get :index, params: { client_name: 'Nome do Cliente' }
        expect(response).to be_successful
        expect(response).to have_http_status(200)
      end
    end
  end
end
