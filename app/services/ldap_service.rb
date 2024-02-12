require 'net/ldap'

class LdapService
  def initialize
    @ldap = Net::LDAP.new(
      host: '10.25.0.1',
      port: 389,
      auth: {
        method: :simple,
        username: "diego.lima",
        password: "TanyaDegurechaff69."
      },
      base: 'dc=tote,dc=local'
    )
  end

  def authenticate(username, password)
    user_dn = "CN=#{username},OU=Users,DC=tote,DC=local"

    if @ldap.bind_as(
      base: "dc=tote,dc=local",
      filter: "(&(samaccountname=#{username})(objectCategory=person))",
      password: password
    )
      return true
    else
      return false
    end
  end
end
