module ConnectionDetails
  class AssignmentService
    def fetch_assignment_data(authentication_contract_id)
      authentication_contract = AuthenticationContract.includes(contract: { contract_service_tags: { assignment_incidents: [:incident_type, :assignment => [:person, :team, :report]] } })
                                                      .find_by(id: authentication_contract_id)

      if authentication_contract && authentication_contract.contract
        contract_service_tags = authentication_contract.contract.contract_service_tags
        if contract_service_tags.any?
          assignments_data = contract_service_tags.flat_map do |tag|
            tag.assignment_incidents.map(&:assignment).uniq.map do |assignment|
              incidents = tag.assignment_incidents.select { |incident| incident.assignment_id == assignment.id }
              format_assignment_data(assignment, incidents)
            end
          end

          recent_assignments_count = assignments_data.count { |data| data[:beginning_date] >= 30.days.ago.to_date }

          sorted_assignments = assignments_data.sort_by { |data| data[:beginning_date] }.reverse

          {
            assignments: sorted_assignments.presence || { error: "No assignments found for provided ID." },
            recent_assignments_count: recent_assignments_count,
          }
        else
          { error: "No contract service tags found for provided ID." }
        end
      else
        { error: "No contract found for provided ID." }
      end
    end

    private

    def format_assignment_data(assignment, incidents)
      {
        assignment_id: assignment.id,
        beginning_date: assignment.beginning_date,
        conclusion_date: assignment.conclusion_date,
        team_name: assignment.team&.title,
        requestor_name: assignment.requestor&.name,
        responsible_name: assignment.responsible&.name,
        description: format_description(assignment.description),
        incidents: incidents.map { |incident| format_incident_data(incident, assignment) },
        reports: assignment.report.map { |report| format_report_data(report) },
      }
    end

    def format_incident_data(incident, assignment)
      {
        incident_id: incident.id,
        incident_protocol: incident.protocol,
        incident_type: incident.incident_type&.title,
        incident_description: remove_html(assignment.description),
      }
    end

    def format_report_data(report)
      {
        report_id: report.id,
        report_person: report.person&.name,
        report_title: report.title,
        report_description: remove_html(report.description),
        report_beginning_date: report.beginning_date,
        report_final_date: report.final_date,
        report_private: report.private,
        report_team: report.team&.title,
      }
    end

    def remove_html(description)
      ActionController::Base.helpers.strip_tags(description)
    end

    def format_description(description)
      Sanitize.fragment(description).gsub(/\r\n/, "<br>").html_safe
    end
  end
end
