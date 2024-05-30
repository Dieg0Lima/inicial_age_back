class InvoiceNote < VoalleDataBase
    belongs_to :contract
    has_many :invoice_note_items
  
    validates :document_number, presence: true, uniqueness: true
    validates :issue_date, presence: true
  end
  