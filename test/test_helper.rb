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
  def log_in
    post "/auth/shibboleth/callback", env: {
      "omniauth.auth": {
        provider:          "shibboleth",
        "Shib-Session-ID": SecureRandom.hex,
        uid:               'admin@email.com',
        info: {
          email: 'admin@email.com'
        },
        extra: {
          raw_info: {
          }
        }
      }
    }
  end

  def log_out 
    delete sign_out_path 
  end

  ##
  # Creates the S3 buckets (if necessary).
  #
  def setup_s3
    # Book bucket
    store  = BookStore.instance
    store.create_bucket(bucket: BookStore::BUCKET) unless store.bucket_exists?
    store.delete_objects
    # Temp bucket
    store  = TempStore.instance
    store.create_bucket(bucket: TempStore::BUCKET) unless store.bucket_exists?
    store.delete_objects
  end

  def teardown_s3
    store = BookStore.instance
    store.delete_objects if store.bucket_exists?
    store = TempStore.instance
    store.delete_objects if store.bucket_exists?
  end

end
