module Sap
  class BusinessPartnersController < ApplicationController
    include B1SlayerAuthentication

    def create
      business_partner_data = business_partner_params.to_h
      business_partner_data[:Frozen] = map_boolean_to_enum(business_partner_data[:Frozen])

      response = B1SlayerIntegration.create_business_partner(business_partner_data, b1_cookies)
      if response[:error]
        render json: { error: response[:error], code: response[:code], details: response[:body] }, status: :unprocessable_entity
      else
        render json: { message: "Business Partner created successfully", business_partner: response }, status: :created
      end
    end

    private

    def business_partner_params
      params.require(:business_partner).permit(
        :CardCode, :CardName, :CardType, :GroupCode, :EmailAddress, :Frozen, :Series, :Phone1, :Phone2,
        BPAddresses: [
          :AddressName, :Street, :Block, :ZipCode, :City, :County, :Country, :State,
          :BuildingFloorRoom, :AddressType, :TypeOfAddress, :StreetNo, :RowNum,
        ],
        BPFiscalTaxIDCollection: [
          :Address, :TaxId0, :TaxId1, :TaxId4, :AddrType,
        ],
      )
    end

    def map_boolean_to_enum(value)
      case value
      when true
        "tYES"
      when false
        "tNO"
      else
        value
      end
    end
  end
end
