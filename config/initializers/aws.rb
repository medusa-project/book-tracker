# https://docs.aws.amazon.com/sdk-for-ruby/v3/api/index.html

require 'configuration'

config = ::Configuration.instance
opts   = {}

if Rails.env.development? || Rails.env.test?
  # In development and test, we connect to a custom endpoint, and credentials
  # are drawn from the application configuration.
  opts[:endpoint]         = config.aws_endpoint
  opts[:force_path_style] = true
  opts[:credentials]      = Aws::Credentials.new(config.aws_access_key_id,
                                                 config.aws_secret_access_key)
end

Aws.config.update(opts)
