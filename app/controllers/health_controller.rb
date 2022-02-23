class HealthController < ApplicationController

  ##
  # Responds to GET /health
  #
  def check
    render plain: 'OK'
  end

  ##
  # Responds to /error with HTTP 500. Used for testing CloudWatch alarms.
  #
  def error
    render plain: '500 Internal Server Error', status: :internal_server_error
  end

end
