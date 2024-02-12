require "test_helper"

class OltConnectionControllerTest < ActionDispatch::IntegrationTest
  test "should get ip" do
      get '/equipamento/obter_ip', params: { title: 'BSA.TGA1.OLT.01 (Taguatinga)' }

      assert_response :success

      response_json = JSON.parse(response.body)
      assert_not_nil response_json['ip']
  end
end
