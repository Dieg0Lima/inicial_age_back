class Signin::LoginController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    input_username = params[:username]
    input_password = params[:password]
  
    if input_username.present? && input_password.present?
      result = LdapAuthenticator.authenticate(input_username, input_password)
      
      if result[:success]
        token = JwtToken.encode(user_id: result[:user][:id])
        render json: { status: 'success', message: 'Login successful', user: result[:user], token: token }, status: :ok
      else
        render json: { status: 'error', message: result[:error] }, status: :unauthorized
      end
    else
      render json: { status: 'error', message: 'Username and password are required' }, status: :bad_request
    end
  end
end
