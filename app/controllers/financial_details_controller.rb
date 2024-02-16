class FinancialDetailsController < ApplicationController
  def financial_info
    contract_id = params[:contract_id]

    results = Contract
      .left_joins(:financial_receivable_titles)
      .select(
        'contracts.id AS contract_number',
        'contracts.collection_day AS collection_day',
        'financial_receivable_titles.expiration_date AS expiration_date',
        'financial_receivable_titles.title AS FAT_number',
        'financial_receivable_titles.pix_qr_code AS Qr_code_PIX',
        'financial_receivable_titles.typeful_line AS Bar_code',
        'financial_receivable_titles.title_amount AS value',
        'financial_receivable_titles.p_is_receivable AS payment_status'
      )
      .where("contracts.id = ? AND financial_receivable_titles.title ILIKE ? AND financial_receivable_titles.renegotiated = ?", contract_id, "%FAT%", false)
      .order('financial_receivable_titles.expiration_date DESC')
      results = results.map do |record|
        record_attributes = record.attributes
        puts record_attributes["payment_status"].inspect

        record_attributes.merge!(
          "value" => format_currency(record_attributes["value"]),
          "Boleto_situation" => record_attributes["payment_status"] ? 'Em aberto' : 'Pago'
        )
      end

    if results.any?
      render json: results
    else
      render json: { error: "Nenhuma informação financeira encontrada para o contrato #{contract_id}." }, status: :not_found
    end
  end

  private

    def format_currency(amount)
      ActionController::Base.helpers.number_to_currency(amount, unit: "R$", separator: ",", delimiter: ".", format: "%u %n")
    end
end
