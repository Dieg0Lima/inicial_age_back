class SearchClientService
  def initialize(value)
    @value = value
  end

  def search
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
      latest_address.neighborhood
      latest_address.street
      latest_address.postal_code
    ].join(", ")

    last_addresses_subquery = PeopleAddress.select("DISTINCT ON (person_id) *")
                                           .order("person_id, id DESC")
                                           .to_sql

    if numeric?(@value)
      results = AuthenticationContract.joins(contract: :person)
                                      .joins("INNER JOIN (#{last_addresses_subquery}) latest_address ON latest_address.person_id = people.id")
                                      .select(select_columns)
                                      .where("authentication_contracts.contract_id = ?", @value.to_i)
      return results if results.exists?
    end

    name_results = AuthenticationContract.joins(contract: :person)
                                         .joins("INNER JOIN (#{last_addresses_subquery}) latest_address ON latest_address.person_id = people.id")
                                         .select(select_columns)
                                         .where("people.name ILIKE ?", "%#{@value}%")
    return name_results if name_results.exists?

    conditions = build_conditions(AuthenticationContract.column_names - %w[id created_at updated_at])

    AuthenticationContract.joins(contract: :person)
                          .joins("INNER JOIN (#{last_addresses_subquery}) latest_address ON latest_address.person_id = people.id")
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
