class InvoiceNoteItem < VoalleDataBase
  belongs_to :invoice_note

  self.inheritance_column = :_type_disabled
end
