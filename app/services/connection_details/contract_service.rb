module ConnectionDetails
  class ContractService
    def fetch_contract_data(authentication_contract_id)
      authentication_contract = AuthenticationContract.includes(:contract)
                                                      .find_by(id: authentication_contract_id)

      if authentication_contract && authentication_contract.contract
        contract = authentication_contract.contract
        contract_data = {
          contract_id: contract.id,
          status: contract.v_status,
          stage: contract.v_stage,
          beginning_date: contract.beginning_date,
          final_date: contract.final_date,
        }
        contract_data
      else
        { error: "No data found for provided ID." }
      end
    end
  end
end
