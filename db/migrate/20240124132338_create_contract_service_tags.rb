class CreateContractServiceTags < ActiveRecord::Migration[7.1]
  def change
    create_table :contract_service_tags do |t|

      t.timestamps
    end
  end
end
