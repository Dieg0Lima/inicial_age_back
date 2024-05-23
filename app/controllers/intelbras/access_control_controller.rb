module Intelbras
  class AccessControlController < ApplicationController
    def open_door
      open_door_service = IntelbrasServices::OpenDoorService.new("192.168.68.5", "admin", "@Age145236#")
      door_response = open_door_service.open_door
      if door_response && !door_response.key?(:error)
        render json: { status: "Success", message: "Door opened successfully.", data: door_response }, status: :ok
      else
        render json: { status: "Error", message: "Failed to open the door.", details: door_response }, status: :unprocessable_entity
      end
    end
  end
end
