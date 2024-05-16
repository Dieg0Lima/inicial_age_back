class AuthenticationAddressList < VoalleDataBase
  self.inheritance_column = :_type_disabled
  self.ignored_columns = ["hash"]
  alias_method :hash_key, :hash

  has_many :authentication_contract
end
