class Team < VoalleDataBase
  self.ignored_columns = ["hash"]
  has_many :assignment
  has_many :report
  alias_method :hash_key, :hash
end
