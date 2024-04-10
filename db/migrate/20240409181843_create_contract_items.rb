class CreateContractItems < ActiveRecord::Migration[7.1]
  def change
    create_table :contract_items do |t|

      t.timestamps
    end
  end
end
