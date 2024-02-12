class AuthenticationIp < ApplicationRecord
  has_many :authentication_access_points
end
