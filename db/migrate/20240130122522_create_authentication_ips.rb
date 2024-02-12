class CreateAuthenticationIps < ActiveRecord::Migration[7.1]
  def change
    create_table :authentication_ips do |t|

      t.timestamps
    end
  end
end
