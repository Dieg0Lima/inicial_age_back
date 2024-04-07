class CreateAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :assignments do |t|

      t.timestamps
    end
  end
end
