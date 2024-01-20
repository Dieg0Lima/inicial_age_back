class Contract < ApplicationRecord
  # Associações (ajuste-as conforme seu modelo)
  belongs_to :client, class_name: 'Person', foreign_key: 'client_id'
  belongs_to :people_address
  has_many :contract_items
  has_many :service_products, through: :contract_items

  # Supondo que estas associações estejam definidas em seus respectivos modelos

  def self.custom_query(client_name = nil, page: 1, per_page: 10)
    contracts = Contract.joins(:client, :people_address, :service_products)
                        .select(
                          'contracts.contract_number AS contrato',
                          'contracts.v_status AS status_contrato',
                          'contracts.v_stage AS estagio_contrato',
                          'contracts.beginning_date AS inicio_do_contrato',
                          'contracts.unblock_attempt_count AS desbloqueios_realizados',
                          'people_addresses.street AS endereco',
                          'people_addresses.postal_code AS cep',
                          'service_products.title AS plano',
                          'clients.name AS cliente',
                          'clients.tx_id AS cpf_cnpj'
                        )

    contracts = contracts.where('clients.name ILIKE ?', "%#{client_name}%") if client_name.present?
    contracts = contracts.where('service_products.title ILIKE ?', '%plano%')

    Kaminari.paginate_array(contracts).page(page).per(per_page)
  end
end
