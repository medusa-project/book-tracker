if ENV['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI']
  require 'net/http'
  uri = URI("http://169.254.170.2#{ENV['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI']}")
  begin
    res = Net::HTTP.get_response(uri)
    Rails.logger.warn("[ECS Metadata Check] HTTP status: #{res.code}")
    Rails.logger.warn("[ECS Metadata Check] Body: #{res.body}")
  rescue => e
    Rails.logger.error("[ECS Metadata Check] Error retrieving ECS credentials endpoint: #{e}")
  end
else
  Rails.logger.warn("[ECS Metadata Check] AWS_CONTAINER_CREDENTIALS_RELATIVE_URI not set")
end