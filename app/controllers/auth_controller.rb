class AuthController < ApplicationController
  require 'net/ldap'
  require 'jwt'

  def login
    user_dn = "cn=#{params[:username]},#{base_dn}"
    password = params[:password]

    if authenticate_ldap(user_dn, password)
      render json: { token: generate_jwt(user_dn) }, status: :ok
    else
      render json: { error: 'Credenciais inválidas' }, status: :unauthorized
    end
  end

  private

  def base_dn
    ENV['LDAP_BASE_DN']
  end

  def ldap_host
    ENV['LDAP_HOST']
  end

  def jwt_secret
    ENV['JWT_SECRET']
  end

  def authenticate_ldap(user_dn, password)
    ldap = Net::LDAP.new(host: ldap_host, port: 389)
    ldap.auth(user_dn, password)
    ldap.bind
  end

  def generate_jwt(user_dn)
    payload = {
      user: user_dn,
      exp: Time.now.to_i + 60 * 60,
      iat: Time.now.to_i
    }
    JWT.encode(payload, jwt_secret, 'HS256')
  end
end
