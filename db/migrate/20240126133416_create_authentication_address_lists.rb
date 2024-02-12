class CreateAuthenticationAddressLists < ActiveRecord::Migration[7.1]
  def change
    create_table :authentication_address_lists do |t|

      t.timestamps
    end
  end
end
