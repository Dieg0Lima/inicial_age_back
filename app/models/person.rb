class Person < VoalleDataBase
  self.table_name = "people"
  has_many :contracts, foreign_key: "client_id", class_name: "Contract"
  has_many :people_addresses, foreign_key: "person_id", class_name: "PeopleAddress"
  has_many :assignment_incident
  has_many :assignment
  has_many :report
  belongs_to :insignia, class_name: "Insignia", foreign_key: "insignia_id"
  has_many :invoice_notes, through: :contracts
end
