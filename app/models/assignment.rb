class Assignment < ApplicationRecord
  has_many :assignment_incidents
  belongs_to :people, foreign_key: 'responsible_id'
end
