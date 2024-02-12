require 'rails_helper'

RSpec.describe OltController, type: :controller do
  describe '#execute_command' do
    it 'executes the SSH command' do
      allow(Net::SSH).to receive(:start).and_yield(fake_ssh_object)

      get :execute_command

      expect(response).to have_http_status(:no_content)

    end

    it 'handles SSH errors' do
      allow(Net::SSH).to receive(:start).and_raise(Net::SSH::Exception.new('SSH Error'))

      get :execute_command

      expect(response).to have_http_status(:internal_server_error)

      expect(JSON.parse(response.body)['error']).to eq('SSH Error')
    end
  end

  def fake_ssh_object
    fake_ssh = double
    allow(fake_ssh).to receive(:exec!).and_yield(nil, nil, 'Fake SSH Response')
    fake_ssh
  end
end
