module ConnectionDetails
  class AssignmentService
    def fetch_assignment_data(authentication_contract_id)
      authentication_contract = AuthenticationContract.includes(contract: { contract_service_tags: { assignment_incidents: [:incident_type, { assignment: [:person, :team] }] } })
                                                      .find_by(id: authentication_contract_id)

      if authentication_contract && authentication_contract.contract
        contract_service_tags = authentication_contract.contract.contract_service_tags
        if contract_service_tags.any?
          assignment_data = contract_service_tags.flat_map do |tag|
            tag.assignment_incidents.map do |incident|
              {
                incident_id: incident.id,
                incident_protocol: incident.protocol,
                incident_type: incident.incident_type.title,
                beginning_date: incident.assignment.beginning_date,
                conclusion_date: incident.assignment.conclusion_date,
                team_name: incident.assignment.team.title,
                requestor_name: incident.assignment.requestor&.name,
                responsible_name: incident.assignment.responsible&.name,
                description: format_description(incident.assignment.description),
              }
            end
          end

          assignment_data.presence || { error: "No assignment incidents found for provided ID." }
        else
          { error: "No contract service tags found for provided ID." }
        end
      else
        { error: "No contract found for provided ID." }
      end
    end

    private

    def format_description(description)
      description.gsub(/\r\n/, "<br>").html_safe
    end
  end
end
