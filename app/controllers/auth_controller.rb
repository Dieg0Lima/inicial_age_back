require 'net/ldap'
require 'jwt'

class AuthController < ApplicationController
  def login
    username = params[:username]
    password = params[:password]

    if username.blank? || password.blank?
      return render json: { error: 'Nome de usuário e senha são obrigatórios' }, status: :bad_request
    end

    user_dn = construct_user_dn(username)

    if authenticate_ldap(user_dn, password)
      token = generate_jwt(username)
      render json: { token: token }, status: :ok
    else
      render json: { error: 'Credenciais inválidas' }, status: :unauthorized
    end
  end

  private

  def ldap_host
    ENV['LDAP_HOST']
  end

  def ldap_port
    ENV['LDAP_PORT'] || 389
  end

  def base_dn
    ENV['LDAP_BASE_DN']
  end

  def jwt_secret
    ENV['JWT_SECRET']
  end

  def authenticate_ldap(user_dn, password)
    ldap = Net::LDAP.new(host: ldap_host, port: ldap_port, base: base_dn)
    ldap.auth(user_dn, password)

    if ldap.bind
      # Autenticação bem-sucedida
      true
    else
      # Falha na autenticação, logue a mensagem de erro
      Rails.logger.error(ldap.get_operation_result.message)
      false
    end
  end

  def generate_jwt(username)
    payload = {
      username: username,
      exp: Time.now.to_i + 60 * 60, # Token expira em uma hora
      iat: Time.now.to_i
    }
    JWT.encode(payload, jwt_secret, 'HS256')
  end

  def construct_user_dn(username)
    "CN=#{username},CN=Users,DC=tote,DC=local"
  end

end
