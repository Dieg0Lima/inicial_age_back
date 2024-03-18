require 'net/ldap'

class LdapAuthenticator
  def self.authenticate(input_username, input_password)
    ldap_host = ENV['LDAP_HOST']
    admin_username = ENV['LDAP_ADMIN_USERNAME']
    admin_password = ENV['LDAP_ADMIN_PASSWORD']
    base_dn = '@tote.local'
    base = 'dc=tote,dc=local'

    ldap = Net::LDAP.new
    ldap.host = ldap_host
    ldap.port = 389
    ldap.auth admin_username, admin_password

    if ldap.bind
      user_dn = "#{input_username}#{base_dn}"
      ldap.auth user_dn, input_password

      if ldap.bind
        filter = Net::LDAP::Filter.eq("sAMAccountName", input_username)
        attributes = ["dn", "givenName", "displayName"]
        user_info = ldap.search(base: base, filter: filter, attributes: attributes, return_result: true)

        if user_info && !user_info.empty?
          dn = user_info.first[:dn]
          given_name = user_info.first[:givenName].first
          display_name = user_info.first[:displayName].first
          
          ou_values = process_dn(user_info.first[:dn])
          
          user_details = {
            given_name: given_name,
            display_name: display_name,
            ou_values: ou_values
          }
          
          { success: true, user: user_details }
        else
          { success: false, error: "Usuário não encontrado após autenticação" }
        end
      else
        { success: false, error: ldap.get_operation_result.message }
      end
    else
      { success: false, error: "Não foi possível conectar com as credenciais de administrador" }
    end
  rescue Net::LDAP::Error => e
    { success: false, error: e.message }
  end

  def self.process_dn(dn_array)
    dn_string = dn_array.first
    dn_string.scan(/OU=([^,]+)/).flatten
  end
  
end
