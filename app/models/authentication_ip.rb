class AuthenticationIp < VoalleDataBase

    has_many :authentication_access_points, foreign_key: 'authentication_ip_id'
end
