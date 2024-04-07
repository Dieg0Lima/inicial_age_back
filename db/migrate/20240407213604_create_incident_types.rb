class CreateIncidentTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :incident_types do |t|

      t.timestamps
    end
  end
end
