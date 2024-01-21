class Contract < ApplicationRecord
  belongs_to :client, class_name: 'Person', foreign_key: 'client_id'
  belongs_to :people_address
  has_many :contract_items
  has_many :service_products, through: :contract_items

  def self.custom_query(contract_id)
    Contract.joins(:client, :people_address, :contract_items, :service_products)
            .joins("LEFT JOIN assignments a ON a.id = contracts.assignment_id")
            .joins("LEFT JOIN authentication_contracts ac ON ac.contract_id = contracts.id")
            .joins("LEFT JOIN authentication_access_points aap ON aap.maintenance_assignment_id = a.id")
            .joins("LEFT JOIN authentication_concentrators ac2 ON ac2.id = ac.authentication_concentrator_id")
            .joins("LEFT JOIN authentication_splitter_ports asp ON asp.authentication_contract_id = ac.id")
            .select(
              'DISTINCT ON (ac.equipment_serial_number) ac.equipment_serial_number',
              'contracts.contract_number AS contrato',
              'people.name AS cliente',
              'contracts.v_status AS status_contrato',
            )
            .where('ac.slot_olt IS NOT NULL')
            .where('contracts.id = ?', contract_id)
            .where('service_products.title ILIKE ?', '%plano%')
  end
end

