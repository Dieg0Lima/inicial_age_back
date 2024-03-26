class CreateVoalleDataBases < ActiveRecord::Migration[7.1]
  def change
    create_table :voalle_data_bases do |t|

      t.timestamps
    end
  end
end
