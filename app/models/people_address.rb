class PeopleAddress < VoalleDataBase
    belongs_to :person, foreign_key: "person_id", class_name: "Person"
    belongs_to :contract
end
