# We need a config/shibboleth.yml file with the options
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
end
OmniAuth.config.logger = Rails.logger
