class AttendantDetailsController < ApplicationController
  def attendant_details
    contract_id = params[:contract_id]

    results = Contract
        .where(id: contract_id)
        .joins(contract_service_tags: { assignment_incidents: { assignment: :people } })
        .select(
            'contract_service_tags.id AS tag_id',
            'contract_service_tags.contract_id AS tag_contract_id',
            'assignments.title AS assignment_title',
            'assignments.created AS assignment_created',
            'assignments.requestor_id AS assignment_requestor_id',
            'assignments.responsible_id AS responsible_id',
            'people.name AS name'
        )
        .order('assignments.beginning_date DESC')
        .map(&:attributes)

    if results.any?
      render json: results
    else
      render json: { error: "Nenhuma informação encontrada para o contrato #{contract_id}." }, status: :not_found
    end
  end
end
