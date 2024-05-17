module Sap
  class ItemsController < ApplicationController
    include B1SlayerAuthentication

    def create
      item_data = item_params.to_h

      response = B1SlayerIntegration.create_item(item_data, b1_cookies)
      if response[:error]
        render json: { error: response[:error], code: response[:code], details: response[:body] }, status: :unprocessable_entity
      else
        render json: { message: "Item created successfully", item: response }, status: :created
      end
    end

    private

    def item_params
      params.require(:item).permit(
        :ItemCode, :ItemName, :ItemsGroupCode, :ItemType, :InventoryItem, :SalesItem, :PurchaseItem,
        :ManageSerialNumbers, :ManageBatchNumbers, :UoMGroupEntry, :DefaultWarehouse
      )
    end
  end
end
