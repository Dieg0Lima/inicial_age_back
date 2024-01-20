class Contract < ApplicationRecord
    def self.custom_query(client_name = nil, page: 1, per_page: 10)    sql = <<-SQL
      SELECT
        c.contract_number as "Contrato",
        c.v_status as "Status Contrato",
        c.v_stage as "Estagio Contrato",
        c.beginning_date as "Inicio do Contrato",
        c.unblock_attempt_count as "Desbloqueios Realizados",
        pa.street as "Endereco",
        pa.postal_code as "CEP",
        sp.title as "Plano",
        p.name as "Cliente",
        p.tx_id as "CPF/CNPJ"
      FROM erp.contracts c
      LEFT JOIN erp.people_addresses pa ON c.people_address_id = pa.id
      LEFT JOIN erp.contract_items ci ON c.id = ci.contract_id
      LEFT JOIN erp.service_products sp ON ci.service_product_id = sp.id
      LEFT JOIN erp.people p ON c.client_id = p.id
      AND sp.title ILIKE '%plano%';
    SQL

    binds = []
    if client_name.present?
      sql += " WHERE p.name ILIKE :client_name "
      binds << ActiveRecord::Relation::QueryAttribute.new("client_name", "%#{client_name}%", ActiveRecord::Type::String.new)
    end

    sql += "AND sp.title ILIKE '%plano%'"

    result = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)
    result.to_a
    Kaminari.paginate_array(contracts).page(page).per(per_page)
  end
end
