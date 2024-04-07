class IncidentType < VoalleDataBase
  self.inheritance_column = "inheritance_type"

  has_many :assignment_incident
end
