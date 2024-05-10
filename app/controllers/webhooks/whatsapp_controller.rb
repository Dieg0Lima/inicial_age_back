module Webhooks
  class WhatsappController < ApplicationController
    def infobip
      data = JSON.parse(request.body.read)
      message = data["message"]
      sender = data["from"]

      render json: { status: "success", sender: sender, message: message }, status: :ok
    end
  end
end
