module JwtToken
  SECRET_KEY = Rails.application.credentials.jwt_secret_key

  if SECRET_KEY.blank?
    Rails.logger.error 'JWT secret key not configured in production'
    raise 'JWT secret key not configured'
  else
    Rails.logger.info 'JWT secret key loaded successfully'
  end

  def self.encode(payload, exp = 6.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    body = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new body
  rescue JWT::ExpiredSignature, JWT::VerificationError => e
    Rails.logger.error "JWT Error: #{e.message}"
    raise e
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT Decode Error: #{e.message}"
    raise e
  end
end
