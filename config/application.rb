require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BookTracker
  class Application < Rails::Application
    attr_accessor :shibboleth_host

    config.load_defaults "6.0"

    config.time_zone = ENV['TIME_ZONE'] || 'America/Chicago'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
