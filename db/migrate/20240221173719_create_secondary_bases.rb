class CreateSecondaryBases < ActiveRecord::Migration[7.1]
  def change
    create_table :secondary_bases do |t|

      t.timestamps
    end
  end
end
