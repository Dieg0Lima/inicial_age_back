class People < ApplicationRecord
    self.table_name = "people"
    has_many :assignments
    has_many :authentication_contract
end
