class Insignia < VoalleDataBase
  self.ignored_columns = ["hash"]

  alias_method :hash_key, :hash

  self.table_name = "insignias"
  has_many :people, class_name: "Person", foreign_key: "insignia_id"
end
