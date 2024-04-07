module Authentication
  class ValidateController < ApplicationController
    def authenticate_request(token)
      return { error: 'Token não fornecido', status: :unauthorized } unless token

      decoded_token = JwtToken.decode(token)
      return { error: 'Token inválido', status: :unauthorized } unless decoded_token

      user = User.find_by(id: decoded_token[:user_id])
      return { error: 'Usuário não encontrado', status: :unauthorized } unless user

      { user: user }
    rescue JWT::ExpiredSignature, JWT::VerificationError
      { error: 'Falha ao decodificar o token', status: :unauthorized }
    end
  end
end
