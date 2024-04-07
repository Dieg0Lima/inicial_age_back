module ConnectionDetails
  class ConnectionService
    def fetch_connection_data(authentication_contract_id)
      authentication_contract = AuthenticationContract.includes(:contract, :authentication_access_point)
                                                      .find_by(id: authentication_contract_id)

      if authentication_contract
        authentication_access_point = authentication_contract.authentication_access_point
        equipment_port_number = authentication_contract.equipment_port.to_i
        contract_data = {
          authentication_id: authentication_contract.id,
          wifi_name: authentication_contract.wifi_name,
          wifi_password: authentication_contract.wifi_password,
          access_point: authentication_access_point ? authentication_access_point.title : "N/A",
          port_olt: authentication_contract.port_olt,
          slot_olt: authentication_contract.slot_olt,
          equipment_port: equipment_port_number,
          equipment_serial_number: authentication_contract.equipment_serial_number,
        }
        contract_data
      else
        { error: "No data found for provided ID." }
      end
    end
  end
end
