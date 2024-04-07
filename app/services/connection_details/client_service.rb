module ConnectionDetails
  class ClientService
    def fetch_client_data(authentication_contract_id)
      authentication_contract = AuthenticationContract.includes(contract: { person: :people_addresses })
                                                      .find_by(id: authentication_contract_id)

      if authentication_contract && authentication_contract.contract && authentication_contract.contract.person
        person = authentication_contract.contract.person
        last_address = person.people_addresses.last
        person_data = {
          person_id: person.id,
          name: person.name,
          tx_id: person.tx_id,
          cell_phone_1: person.cell_phone_1,
          cell_phone_2: person.cell_phone_2,
          email: person.email,
          address_id: last_address.id,
          street: last_address.street,
          neighborhood: last_address.neighborhood,
          number: last_address.number,
          address_complement: last_address.address_complement,
          postal_code: last_address.postal_code,
        }
        person_data
      else
        { error: "No data found for provided ID." }
      end
    end
  end
end
