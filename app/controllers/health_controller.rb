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

end
