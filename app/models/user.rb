class User < ApplicationRecord
    validates :name, presence: true
    validates :username, presence: true, uniqueness: true
    
    def self.find_or_create_from_ldap_result(ldap_result)
      find_or_create_by(username: ldap_result[:display_name]) do |user|
        user.name = ldap_result[:display_name]
      end
    end
end
  