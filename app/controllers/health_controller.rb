class HealthController < ApplicationController

  ##
  # Responds to GET /health
  #
  def check
    # exercise the database, except in demo, where the database is running in
    # Aurora and saves us money while it's idle.
    Book.all.limit(1).pluck(:id) unless Rails.env.demo?

    render plain: 'OK'
  end

  ##
  # Responds to /error with HTTP 500. Used for testing CloudWatch alarms.
  #
  def error
    render plain: '500 Internal Server Error', status: :internal_server_error
  end

end
