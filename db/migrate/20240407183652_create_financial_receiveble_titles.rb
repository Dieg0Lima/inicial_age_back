class CreateFinancialReceivebleTitles < ActiveRecord::Migration[7.1]
  def change
    create_table :financial_receiveble_titles do |t|

      t.timestamps
    end
  end
end
