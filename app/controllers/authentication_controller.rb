require 'jwt'

class AuthenticationController < ApplicationController
  def login
    ldap_service = LdapService.new

    if ldap_service.authenticate(params[:username], params[:password])
      token = generate_jwt_token(params[:username])
      render json: { token: token }, status: :ok
    else
      render json: { error: 'Credenciais inválidas' }, status: :unauthorized
    end
  end

  private

  def generate_jwt_token(username)
    payload = { user_id: username, exp: 24.hours.from_now.to_i }
    hmac_secret = 'fb7f1034e8ea309e07cd90e6aaded9e1422e93762fef865513c945a9fad305043dfbd56a8168e93b6d0ce8144bb2d64f759525c6d881e44c108c04299f07cfcc
'
    JWT.encode(payload, hmac_secret, 'HS256')
  end
end
