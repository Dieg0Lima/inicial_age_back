class CreateAuthenticationAccessPoints < ActiveRecord::Migration[7.1]
  def change
    create_table :authentication_access_points do |t|

      t.timestamps
    end
  end
end
