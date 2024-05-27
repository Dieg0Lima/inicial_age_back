class ExportQueue < ApplicationRecord
    belongs_to :customer, class_name: 'Person', foreign_key: 'customer_id'
  
    validates :customer_id, presence: true
    validates :export_scheduled_at, presence: true
end
  