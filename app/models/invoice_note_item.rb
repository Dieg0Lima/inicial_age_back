class InvoiceNoteItem < VoalleDataBase
  self.inheritance_column = :_type_disabled


  belongs_to :invoice_note
  
  validates :description, presence: true
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
  