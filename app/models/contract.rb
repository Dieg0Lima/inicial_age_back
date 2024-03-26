class Contract < VoalleDataBase
  belongs_to :person, foreign_key: "client_id", class_name: "Person"
  has_many :authentication_contracts
  has_many :people_addresses
end
