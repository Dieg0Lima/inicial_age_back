module JwtToken
    SECRET_KEY = Rails.application.credentials.jwt_secret_key
  
    def self.encode(payload, exp = 6.hours.from_now)
      payload[:exp] = exp.to_i
      JWT.encode(payload, SECRET_KEY)
    end
  
    def self.decode(token)
      body = JWT.decode(token, SECRET_KEY)[0]
      HashWithIndifferentAccess.new body
    rescue JWT::ExpiredSignature, JWT::VerificationError => e
      raise e
    end
end
  