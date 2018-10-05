##
# Singleton interface to the application configuration.
#
# Usage:
#
# Configuration.instance.key_name (shorthand for
# Configuration.instance.get(:key_name))
#
class Configuration

  include Singleton

  def initialize
    @config = YAML.load(
        ERB.new(
            File.read(
                File.join(Rails.root, 'config', 'book_tracker.yml'))).result)[Rails.env]
  end

  ##
  # @return [Object]
  #
  def get(key)
    @config[key.to_sym]
  end

  def method_missing(m, *args, &block)
    self.respond_to?(m) ? super : get(m)
  end

end
