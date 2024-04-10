class ContractItem < VoalleDataBase
    self.inheritance_column = "inheritance_type"

    has_many :authentication_contract
end
