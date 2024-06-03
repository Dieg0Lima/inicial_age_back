module Sap
  class InvoicesController < ApplicationController
    include B1SlayerAuthentication

    def create
      invoice_data = prepare_invoice_data(invoice_params.to_h)

      response = B1SlayerIntegration.create_invoice(invoice_data, b1_cookies)
      handle_response(response)
    end

    private

    def invoice_params
      params.require(:invoice).permit(
        :DocEntry, :DocNum, :DocType, :DocDate, :DocDueDate, :CardCode, :CardName, :Comments,
        :BPL_IDAssignedToInvoice, :DocTotal, :Incoterms, :SequenceModel, :SequenceCode, :SequenceSerial, :SeriesString, :IndFinal,
        DocumentLines: [
          :LineNum, :ItemCode, :ItemDescription, :Quantity, :Price, :DiscountPercent,
          :TaxCode, :WarehouseCode, :AccountCode, :Usage,
        ],
        AddressExtension: [
          :ShipToStreet, :ShipToBlock, :ShipToZipCode, :ShipToCity, :ShipToState, :ShipToCountry,
        ],
        Package: {},
      )
    end

    def prepare_invoice_data(data)
      data[:DocDate] = format_date(data[:DocDate])
      data[:DocDueDate] = format_date(data[:DocDueDate])
      data
    end

    def format_date(date)
      Date.parse(date).strftime("%Y-%m-%d") rescue date
    end

    def handle_response(response)
      if response[:error]
        render json: { error: response[:error], code: response[:code], details: response[:body] }, status: :unprocessable_entity
      else
        render json: { message: "Invoice created successfully", invoice: response }, status: :created
      end
    end
  end
end
