class FinancialReceivableTitle < VoalleDataBase
  self.inheritance_column = "inheritance_type"
  belongs_to :contract
end
