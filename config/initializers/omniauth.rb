Rails.application.config.middleware.use OmniAuth::Builder do
  if Rails.env.production? or Rails.env.demo?
    opts = YAML.load(
        ERB.new(
            File.read(
                File.join(Rails.root, 'config', 'shibboleth.yml'))).result, aliases: true)[Rails.env]
    provider :shibboleth, opts.symbolize_keys
    BookTracker::Application.shibboleth_host = opts['host']
  else
    provider :developer
  end

  # Even though SAML isn't used in development/test, we configure it there
  # anyway in order to preview the metadata.
  # See: https://github.com/omniauth/omniauth-saml
  # Metadata URL: http://localhost:3000/auth/saml/metadata
  certs_dir = File.join(Rails.root, "config", "certs")
  idp_cert  = File.read(File.join(certs_dir, "itrust.pem"))
  sp_cert   = (Rails.env.development? || Rails.env.test?) ?
                File.read(File.join(certs_dir, "sp-cert-demo.pem")) : # it doesn't matter here
                File.read(File.join(certs_dir, "sp-cert-#{Rails.env}.pem"))
  config    = ::Configuration.instance
  provider :saml,
           sp_entity_id:        config.saml&[:sp_entity_id],
           idp_sso_service_url: "https://discovery.illinois.edu/discovery/DS",
           idp_sso_service_url_runtime_params: {
             original_request_param: :mapped_idp_param
           },
           idp_cert:               idp_cert,
           certificate:            sp_cert,
           private_key:            config.saml&[:sp_private_key],
           name_identifier_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
end

OmniAuth.config.logger = Rails.logger
