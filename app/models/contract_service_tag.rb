class ContractServiceTag < ApplicationRecord
  belongs_to :contract
  has_many :assignment_incidents
end
