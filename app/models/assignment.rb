class Assignment < VoalleDataBase
  belongs_to :person
  belongs_to :requestor, class_name: 'Person', foreign_key: 'requestor_id'
  belongs_to :responsible, class_name: 'Person', foreign_key: 'responsible_id'
  belongs_to :team
  has_many :assignment_incidents
end
