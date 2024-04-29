module ConnectionDetails
  class ClientService
    def fetch_client_data(authentication_contract_id)
      authentication_contract = AuthenticationContract.includes(contract: { person: [:people_addresses, :insignia] })
        .find_by(id: authentication_contract_id)

      if authentication_contract && authentication_contract.contract && authentication_contract.contract.person
        person = authentication_contract.contract.person
        last_address = person.people_addresses.last
        insignia = person.insignia

        insignia_description = insignia&.description || "Não Disponível"
        insignia_bg_color = insignia&.background_color || "#FFFFFF" 
        insignia_font_color = insignia&.font_color || "#000000"     

        person_data = {
          person_id: person.id,
          name: person.name,
          tx_id: person.tx_id,
          cell_phone_1: person.cell_phone_1,
          cell_phone_2: person.cell_phone_2 || "Não Disponível",  
          email: person.email,
          address_id: last_address&.id,
          street: last_address&.street || "Endereço não disponível",
          neighborhood: last_address&.neighborhood || "Não Disponível",
          number: last_address&.number || "Não Disponível",
          address_complement: last_address&.address_complement || "",
          postal_code: last_address&.postal_code || "Não Disponível",
          insignia: insignia_description,
          insignia_bg_color: insignia_bg_color,
          insignia_font_color: insignia_font_color,
        }
        person_data
      else
        { error: "No data found for provided ID." }
      end
    end
  end
end
