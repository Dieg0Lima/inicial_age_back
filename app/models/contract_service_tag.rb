class ContractServiceTag < VoalleDataBase
    belongs_to :contract
    has_many :assignment_incidents
end
