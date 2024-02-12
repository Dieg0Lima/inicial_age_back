class Contract < ApplicationRecord
  has_many :authentication_contracts
  belongs_to :people_address
  belongs_to :people
  has_many :contract_service_tags
  has_many :financial_receivable_titles
  belongs_to :client, class_name: 'People', foreign_key: 'client_id'
  has_many :assignment_incidents
  has_many :authentication_contract
end

