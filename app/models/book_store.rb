##
# Not a book store like you'd buy books in, but an interface to the bucket in
# which book records are stored. Wraps an {Aws::S3::Client}, adding some
# convenience methods and forwarding all other method calls to it.
#
# @see https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client.html
#
class BookStore

  include Singleton

  BUCKET = ::Configuration.instance.storage.dig(:books, :bucket)

  def self.client_options
    config                  = ::Configuration.instance
    opts                    = {}
    opts[:region]           = config.storage.dig(:books, :region)
    endpoint                = config.storage.dig(:books, :endpoint)
    opts[:endpoint]         = endpoint if endpoint.present?
    opts[:force_path_style] = endpoint.present?

    access_key_id     = config.storage.dig(:books, :access_key_id)
    secret_access_key = config.storage.dig(:books, :secret_access_key)
    if access_key_id.present? && secret_access_key.present?
      opts[:credentials] = Aws::Credentials.new(access_key_id,
                                                secret_access_key)
    end
    opts
  end

  ##
  # @return [Boolean]
  #
  def bucket_exists?
    begin
      get_client.head_bucket(bucket: BUCKET)
    rescue Aws::S3::Errors::NotFound
      return false
    else
      return true
    end
  end

  def delete_objects
    config     = ::Configuration.instance
    bucket     = config.storage.dig(:books, :bucket)
    bucket     = get_resource.bucket(bucket)
    key_prefix = config.storage.dig(:books, :key_prefix)
    bucket.objects(prefix: key_prefix).each(&:delete)
  end

  def method_missing(m, *args, &block)
    if get_client.respond_to?(m)
      get_client.send(m, *args, &block)
    else
      super
    end
  end

  ##
  # @param key [String]
  # @return [Boolean]
  #
  def object_exists?(key:)
    begin
      get_client.head_object(bucket: BUCKET, key: key)
    rescue Aws::S3::Errors::NotFound
      return false
    else
      return true
    end
  end


  private

  def get_client
    @client = Aws::S3::Client.new(self.class.client_options) unless @client
    @client
  end

  def get_resource
    @resource = Aws::S3::Resource.new(self.class.client_options) unless @resource
    @resource
  end

end