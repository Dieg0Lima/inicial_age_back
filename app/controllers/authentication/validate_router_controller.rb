class Authentication::ValidateRouterController < ApplicationController
    def authenticate_request
      token = extract_token_from_header
  
      unless token
        render json: { error: "Token não fornecido" }, status: :unauthorized
        return
      end
  
      decoded_token = JwtToken.decode(token)
  
      unless decoded_token
        render json: { error: "Token inválido" }, status: :unauthorized
        return
      end
  
      @current_user = User.find_by(id: decoded_token[:user_id])
  
      unless @current_user
        render json: { error: "Usuário não encontrado" }, status: :unauthorized
        return
      end
  
      render json: { message: "Usuário autorizado" }, status: :ok
    rescue JWT::ExpiredSignature, JWT::VerificationError => e
      render json: { error: "Falha ao decodificar o token" }, status: :unauthorized
    end
  
    private
  
    def extract_token_from_header
      header = request.headers["Authorization"]
      header.split(" ").last if header.present?
    end
  end
  