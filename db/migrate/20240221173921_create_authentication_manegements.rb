class CreateAuthenticationManegements < ActiveRecord::Migration[7.1]
  def change
    create_table :authentication_manegements do |t|

      t.timestamps
    end
  end
end
