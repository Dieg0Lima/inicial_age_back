class AuthenticationAccessPoint < VoalleDataBase
  self.inheritance_column = :_type_disabled
  belongs_to :authentication_ip, optional: true
  has_many :authentication_contract
end
