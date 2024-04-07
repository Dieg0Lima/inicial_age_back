class Team < VoalleDataBase
  self.ignored_columns = ["hash"]
  has_many :assignment
  alias_method :hash_key, :hash
end
