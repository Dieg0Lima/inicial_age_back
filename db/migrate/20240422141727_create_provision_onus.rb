class CreateProvisionOnus < ActiveRecord::Migration[7.1]
  def change
    create_table :provision_onus do |t|
      t.integer :connection_id
      t.integer :olt_id
      t.string :contract
      t.string :sernum
      t.integer :slot
      t.integer :pon
      t.integer :port
      t.string :provisioned_by
      t.string :cto

      t.timestamps
    end
  end
end
