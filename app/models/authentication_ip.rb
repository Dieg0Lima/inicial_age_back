class AuthenticationIp < VoalleDataBase
  self.inheritance_column = :_type_disabled
  self.ignored_columns = ["hash"]
  alias_method :hash_key, :hash

  has_many :authentication_access_points, foreign_key: "authentication_ip_id"
end
