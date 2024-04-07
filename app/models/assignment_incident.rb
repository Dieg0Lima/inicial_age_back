class AssignmentIncident < VoalleDataBase
  self.inheritance_column = "inheritance_type"

  belongs_to :contract_service_tag
  belongs_to :person
  belongs_to :assignment
  belongs_to :incident_type
end
