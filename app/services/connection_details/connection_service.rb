module ConnectionDetails
  class ConnectionService
    def fetch_connection_data(authentication_contract_id)
      authentication_contract = AuthenticationContract.includes(:contract, :authentication_access_point, :authentication_address_list)
                                                      .find_by(id: authentication_contract_id)

      if authentication_contract
        authentication_access_point = authentication_contract.authentication_access_point
        authentication_address_list = authentication_contract.authentication_address_list

        contract_data = {
          authentication_id: authentication_contract.id,
          wifi_name: authentication_contract.wifi_name,
          wifi_password: authentication_contract.wifi_password,
          access_point_id: authentication_access_point.id,
          access_point: authentication_access_point ? authentication_access_point.title : "N/A",
          port_olt: authentication_contract.port_olt,
          slot_olt: authentication_contract.slot_olt,
          olt_id: authentication_contract.olt_id,
          equipment_serial_number: authentication_contract.equipment_serial_number,
          authentication_address_list_title: authentication_address_list ? authentication_address_list.title : "N/A"
        }
        contract_data
      else
        { error: "No data found for provided ID." }
      end
    end
  end
end