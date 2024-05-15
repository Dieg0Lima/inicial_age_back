class AuthenticationAddressList < VoalleDataBase
  self.inheritance_column = :_type_disabled
  has_many :authentication_contract
end
