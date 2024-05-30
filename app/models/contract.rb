class Contract < VoalleDataBase
  belongs_to :person, foreign_key: "client_id", class_name: "Person"
  has_many :authentication_contracts
  has_many :people_addresses
  has_many :financial_receivable_title
  has_many :contract_service_tags
  has_many :invoice_notes
  has_many :invoice_note_items, through: :invoice_notes
end
