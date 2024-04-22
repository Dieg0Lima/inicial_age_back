class AddUniqueConstraintToSernumInProvisionOnus < ActiveRecord::Migration[7.1]
  def change
    add_index :provision_onus, :sernum, unique: true
  end
end
