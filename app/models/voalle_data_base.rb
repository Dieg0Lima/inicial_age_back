class VoalleDataBase < ApplicationRecord
    self.abstract_class = true
    establish_connection :voalle_db
end

