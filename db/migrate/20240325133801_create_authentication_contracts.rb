class CreateAuthenticationContracts < ActiveRecord::Migration[7.1]
  def change
    create_table :authentication_contracts do |t|

      t.timestamps
    end
  end
end
