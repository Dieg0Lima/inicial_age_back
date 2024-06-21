class NativeDataBase < ApplicationRecord
  self.abstract_class = true
  establish_connection :native_db
end
