class CreateInsignia < ActiveRecord::Migration[7.1]
  def change
    create_table :insignia do |t|

      t.timestamps
    end
  end
end
