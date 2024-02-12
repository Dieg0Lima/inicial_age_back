class AuthenticationContract < ApplicationRecord
  belongs_to :authentication_access_point
  belongs_to :authentication_address_list
  belongs_to :service_product
  belongs_to :contract
end
