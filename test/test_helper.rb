ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
  ##
# @param user [User]
#
  def log_in_as(user)
    post "/auth/shibboleth/callback", env: {
      "omniauth.auth": {
        provider:          "shibboleth",
        "Shib-Session-ID": SecureRandom.hex,
        uid:               user.email,
        info: {
          email: user.email
        },
        extra: {
          raw_info: {
          }
        }
      }
    }
  end
end
