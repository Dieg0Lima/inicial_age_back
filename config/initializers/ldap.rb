LDAP_CONFIG = {
  host: '10.25.0.1',
  port: 636,
  encryption: {
    method: :simple_tls,
    tls_options: OpenSSL::SSL::SSLContext::DEFAULT_PARAMS
  },
  auth: {
    method: :simple,
    username: "cn=diego.lima,dc=tote,dc=local",
    password: "TanyaDegurechaff69."
  },
  base: "dc=tote,dc=local"
}
