# https://docs.aws.amazon.com/sdk-for-ruby/v3/api/index.html

require 'configuration'

config = ::Configuration.instance

Aws.config.update(
    credentials: Aws::Credentials.new(config.aws_access_key_id || ENV['AWS_ACCESS_KEY_ID'],
                                      config.aws_secret_access_key || ENV['AWS_SECRET_ACCESS_KEY']),
    region: config.aws_region || ENV['AWS_REGION'])
