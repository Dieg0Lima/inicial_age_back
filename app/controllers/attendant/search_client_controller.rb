class Attendant::SearchClientController < ApplicationController
  def search
    value = params[:value]
    
    if value.present?
      search_service = SearchClientService.new(value)
      authentication = search_service.search
      render json: authentication
    else
      render json: { error: 'A search value must be provided' }, status: :bad_request
    end
  end
end
