class Signin::LoginController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    input_username = params[:username]
    input_password = params[:password]
  
    unless input_username.present? && input_password.present?
      message = 'O nome de usuário e senha são obrigatórios'
      message = 'A senha é obrigatória.' if input_username.present?
      message = 'O nome de usuário é obrigatório.' if input_password.present?

      render json: { status: 'error', message: message }, status: :bad_request
      return 
    end
    
    result = LdapAuthenticator.authenticate(input_username, input_password)
    
    if result[:success]
      user_params = {
        name: result[:user][:display_name],
        username: input_username
      }

      user = User.find_or_create_by(user_params)
      
      token = JwtToken.encode(user_id: user.id)
      
      render json: { status: 'success', message: 'Acesso permitido.', user: user, token: token }, status: :ok
    else
      render json: { status: 'error', message: I18n.t('errors.invalid_credentials') }, status: :unauthorized
    end
  end
end
