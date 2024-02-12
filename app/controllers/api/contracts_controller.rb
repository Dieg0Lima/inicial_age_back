module Api
         class ContractsController < ApplicationController
           SEARCHABLE_FIELDS = {
             'id' => 'contracts.id',
             'status' => 'contracts.v_status',
             'stage' => 'contracts.v_stage',
             'client_name' => 'people.name',
             'tx_id' => 'people.tx_id',
             'email' => 'people.email',
             'cell_phone_1' => 'people.cell_phone_1',
             'cell_phone_2' => 'people.cell_phone_2',
             'street' => 'people_addresses.street',
             'neighborhood' => 'people_addresses.neighborhood',
             'postal_code' => 'people_addresses.postal_code',
             'equipment_serial_number' => 'authentication_contracts.equipment_serial_number',
             'description' => 'authentication_contracts.complement'
           }.freeze

           def search
             query = Contract
               .joins("INNER JOIN people_addresses ON people_addresses.id = contracts.people_address_id")
               .joins("INNER JOIN people ON contracts.client_id = people.id")
               .joins("LEFT JOIN authentication_contracts ON authentication_contracts.contract_id = contracts.id")

             SEARCHABLE_FIELDS.each do |param, column|
               if param == 'id'
                 query = query.where("#{column} = ?", params[param]) if params[param].present?
               else
                 query = query.where("#{column} ILIKE ?", "%#{params[param]}%") if params[param].present?
               end
             end

             query = query.select('authentication_contracts.id AS "Id"', 'contracts.id AS "Contrato"', 'contracts.v_status AS "Status"', 'contracts.v_stage AS "Estagio"', 'people.name AS "Cliente"', 'people.tx_id AS "CPF"', 'people.email AS "Email"', 'people.cell_phone_1 AS "Telefone1"', 'people.cell_phone_2 AS "Telefone2"', 'people_addresses.street AS "Rua"', 'people_addresses.neighborhood AS "Cidade"', 'people_addresses.postal_code AS "CEP"', 'authentication_contracts.equipment_serial_number AS "ONU"', 'authentication_contracts.complement AS "Description"')

             results = query.to_a

             if results.any?
               contracts_data = results.map do |result|
                 {
                   connection_id: result["Id"],
                   id: result["Contrato"],
                   v_status: result["Status"],
                   v_stage: result["Estagio"],
                   client_name: result["Cliente"],
                   tx_id: result["CPF"],
                   email: result["Email"],
                   cell_phone_1: result["Telefone1"],
                   cell_phone_2: result["Telefone2"],
                   street: result["Rua"],
                   neighborhood: result["Cidade"],
                   postal_code: result["CEP"],
                   equipment_serial_number: result["ONU"],
                   complement: result["Description"]
                 }
               end
               render json: { contracts: contracts_data }
             else
               render json: { error: "Nenhum contrato encontrado." }, status: :not_found
             end
           end

def details
    connection = params[:connection_id]

  query = Contract
    .joins("INNER JOIN people_addresses ON people_addresses.id = contracts.people_address_id")
    .joins("INNER JOIN people ON contracts.client_id = people.id")
    .joins("LEFT JOIN authentication_contracts ON authentication_contracts.contract_id = contracts.id")

  if params[:contract].present?
    query = query.where("contracts.id = ?", params[:contract])
  end

  if params[:equipment_serial_number].present?
    query = query.where("authentication_contracts.equipment_serial_number = ?", params[:equipment_serial_number])
  end

  if params[:connection_id].present?
    query = query.where("authentication_contracts.id = ?", params[:connection_id])
  end

  query = query.select(
    "contracts.billing_final_date AS \"Data_vigencia\",
     contracts.billing_beginning_date AS \"Data_adesao\",
     contracts.id AS \"Contrato\",
     contracts.v_status AS \"Status\",
     contracts.v_stage AS \"Estagio\",
     people.name AS \"Cliente\",
     people.tx_id AS \"CPF\",
     people.email AS \"Email\",
     people.cell_phone_1 AS \"Telefone1\",
     people.cell_phone_2 AS \"Telefone2\",
     people_addresses.street AS \"Rua\",
     people_addresses.number AS \"Numero\",
     people_addresses.neighborhood AS \"Cidade\",
     people_addresses.postal_code AS \"CEP\",
     authentication_contracts.equipment_serial_number AS \"ONU\",
     authentication_contracts.complement AS \"Description\",
     (SELECT COUNT(ce.id) FROM contract_events ce WHERE ce.contract_id = contracts.id AND ce.contract_event_type_id IN ('81', '164', '174', '171', '172', '173', '40')) AS \"DESBLOQUEIOS\",
     (SELECT MAX(ce.\"date\") FROM contract_events ce WHERE ce.contract_id = contracts.id AND ce.contract_event_type_id IN ('81', '164', '174', '171', '172', '173', '40')) AS \"ULTIMO_BLOQUEIO\""
  )

  results = query.to_a
  if results.any?
    contracts_data = results.map do |result|
      {
        billing_final_date: result["Data_vigencia"],
        billing_beginning_date: result["Data_adesao"],
        id: result["Contrato"],
        v_status: result["Status"],
        v_stage: result["Estagio"],
        client_name: result["Cliente"],
        tx_id: result["CPF"],
        email: result["Email"],
        cell_phone_1: result["Telefone1"],
        cell_phone_2: result["Telefone2"],
        street: result["Rua"],
        number: result["Numero"],
        neighborhood: result["Cidade"],
        postal_code: result["CEP"],
        equipment_serial_number: result["ONU"],
        complement: result["Description"],
        desbloqueios: result["DESBLOQUEIOS"],
        ultimo_bloqueio: result["ULTIMO_BLOQUEIO"]
      }
    end
    render json: contracts_data
  else
    render json: { error: "Nenhum contrato encontrado." }, status: :not_found
  end
end

  end
end
