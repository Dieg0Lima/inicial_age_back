module ConnectionDetails
  class FinancialService
    def fetch_financial_data(authentication_contract_id)
      authentication_contract = AuthenticationContract.includes(contract: :financial_receivable_title)
                                                      .find_by(id: authentication_contract_id)

      if authentication_contract && authentication_contract.contract
        financial_receivable_title = authentication_contract.contract.financial_receivable_title
        sorted_titles = financial_receivable_title.sort_by { |title| title.expiration_date }.reverse

        filtered_titles = sorted_titles.select do |title|
          title.title.start_with?("FAT")
        end

        financial_data = filtered_titles.map do |title|
          {
            title_id: title.id,
            title: title.title,
            title_amount: title.title_amount,
            title_expiration_date: title.expiration_date,
            title_status: title.p_is_receivable,
          }
        end

        financial_data.presence || { error: "No financial receivable titles starting with 'FAT' found for provided ID." }
      else
        { error: "No data found for provided ID." }
      end
    end
  end
end
