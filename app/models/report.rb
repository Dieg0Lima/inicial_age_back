class Report < VoalleDataBase
  self.inheritance_column = "inheritance_type"

  belongs_to :assignment
  belongs_to :person
end