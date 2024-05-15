class AuthenticationContract < VoalleDataBase
  belongs_to :contract
  belongs_to :authentication_access_point
  belongs_to :contract_item
  belongs_to :authentication_address_list
end
