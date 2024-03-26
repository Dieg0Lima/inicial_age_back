class CreatePeopleAddresses < ActiveRecord::Migration[7.1]
  def change
    create_table :people_addresses do |t|

      t.timestamps
    end
  end
end
