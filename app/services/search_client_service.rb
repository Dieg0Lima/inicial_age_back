class SearchClientService
  def initialize(value)
    @value = value
  end

  def search
    last_addresses_subquery = PeopleAddress.select("DISTINCT ON (people_addresses.person_id) people_addresses.*")
                                           .order("people_addresses.person_id, people_addresses.id DESC")
                                           .to_sql

    select_columns = %w[
      authentication_contracts.id
      authentication_contracts.contract_id
      authentication_contracts.equipment_serial_number
      contracts.description
      contracts.client_id
      contracts.v_stage
      contracts.v_status
      people.name
      people.tx_id
      people.email
      people.cell_phone_1
      people.cell_phone_2
      last_people_addresses.neighborhood
      last_people_addresses.street
      last_people_addresses.postal_code
    ].join(", ")

    if numeric?(@value)
      results = AuthenticationContract.joins(contract: :person)
                                      .joins("JOIN (#{last_addresses_subquery}) as last_people_addresses ON people.id = last_people_addresses.person_id")
                                      .select(select_columns)
                                      .where("authentication_contracts.contract_id = ?", @value.to_i)

      return results if results.exists?
    end

    name_results = AuthenticationContract.joins(contract: { person: :people_addresses })
                                           .joins("JOIN (#{last_addresses_subquery}) as last_people_addresses ON people.id = last_people_addresses.person_id")
                                           .select(select_columns)
                                           .where("people.name ILIKE ?", "%#{@value}%")

    return name_results if name_results.exists?

    conditions = build_conditions(AuthenticationContract.column_names - %w[id created_at updated_at])

    AuthenticationContract.joins(contract: :person)
                          .joins("JOIN (#{last_addresses_subquery}) as last_people_addresses ON people.id = last_people_addresses.person_id")
                          .select(select_columns)
                          .where(conditions.reduce(:or))
  end

  private

  def numeric?(string)
    string.match?(/\A\d+\z/)
  end

  def build_conditions(columns)
    columns.map do |column|
      column_type = AuthenticationContract.columns_hash[column].type

      case column_type
      when :string, :text
        AuthenticationContract.arel_table[column].matches("%#{@value}%")
      when :integer, :float, :decimal
        Arel::Nodes::NamedFunction.new("CAST", [AuthenticationContract.arel_table[column].as("text")]).matches("%#{@value}%")
      else
        nil
      end
    end.compact
  end
end
