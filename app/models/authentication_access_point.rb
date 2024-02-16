class AuthenticationAccessPoint < ApplicationRecord
  belongs_to :authentication_ips
  has_many :authentication_contracts

  self.inheritance_column = "sti_type"

  def self.fetch_olt_name_by_id(olt_id)
      olt = where(id: olt_id)
            .where("title LIKE ?", "BSA%")
            .where.not(title: ["BSA.SAMB.OLT.01-TESTE", "BSA.ASUL.OLT.02 - TESTE ZTE", "BSA.ASUL.RTC.01 - PPPoE (Temporário)"])
            .order("title")
            .first
      olt&.title
  end

  serialize :configuration, JSON
end
