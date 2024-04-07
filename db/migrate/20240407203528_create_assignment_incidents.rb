class CreateAssignmentIncidents < ActiveRecord::Migration[7.1]
  def change
    create_table :assignment_incidents do |t|

      t.timestamps
    end
  end
end
