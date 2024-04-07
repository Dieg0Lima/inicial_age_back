class Person < VoalleDataBase
  self.table_name = "people"
  has_many :contracts, foreign_key: "client_id", class_name: "Contract"
  has_many :people_addresses, foreign_key: 'person_id', class_name: 'PeopleAddress'
  has_many :assignment_incident
  has_many :assignment
end
