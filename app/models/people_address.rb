class PeopleAddress < VoalleDataBase
  self.inheritance_column = "inheritance_type"
  belongs_to :person, foreign_key: "person_id", class_name: "Person"
  belongs_to :contract
end
