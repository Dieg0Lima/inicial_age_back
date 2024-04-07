module Authenticatable
    extend ActiveSupport::Concern
  
    included do
      before_action :authenticate_request
    end
  
    private
  
    def authenticate_request
      token = extract_token_from_header(request.headers['Authorization'])
  
      return render_unauthorized('Token não fornecido') unless token
  
      auth_result = validate_token(token)
  
      if auth_result[:error]
        render_unauthorized(auth_result[:error])
      else
        @current_user = auth_result[:user]
      end
    end
  
    def validate_token(token)
      decoded_token = JwtToken.decode(token)
      return { error: 'Token inválido' } unless decoded_token
  
      user = User.find_by(id: decoded_token[:user_id])
      return { error: 'Usuário não encontrado' } unless user
  
      { user: user }
    rescue JWT::ExpiredSignature, JWT::VerificationError
      { error: 'Falha ao decodificar o token' }
    end
  
    def render_unauthorized(message)
      render json: { error: message }, status: :unauthorized
    end
  
    def extract_token_from_header(authorization_header)
      authorization_header.to_s.split(' ').last if authorization_header.to_s.start_with?('Bearer')
    end
  end
  