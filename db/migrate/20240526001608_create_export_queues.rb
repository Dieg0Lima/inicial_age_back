class CreateExportQueues < ActiveRecord::Migration[6.1]
  def change
    create_table :export_queues do |t|
      t.integer :customer_id, null: false
      t.datetime :export_scheduled_at, null: false

      t.timestamps
    end

    add_index :export_queues, :customer_id
    add_foreign_key :export_queues, :people, column: :customer_id
  end
end
