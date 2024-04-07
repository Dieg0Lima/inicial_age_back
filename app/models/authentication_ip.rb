class AuthenticationIp < VoalleDataBase
    self.inheritance_column = :_type_disabled
    has_many :authentication_access_points, foreign_key: 'authentication_ip_id'
    
end
