class AuthenticationAccessPoint < VoalleDataBase
  self.inheritance_column = :_type_disabled
  belongs_to :authentication_ip, optional: true
  has_many :authentication_contract

  scope :bsa_olts, -> { where("title LIKE ?", "BSA%").where.not(id: [2, 9, 7, 77, 68, 69, 67, 32]).order(:title) }

  def olt_title_with_value
    { olt_name: title, id: id }
  end
end
