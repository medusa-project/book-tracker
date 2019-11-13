class HealthController < ApplicationController

  ##
  # Responds to GET /health
  #
  def check
    Book.all.limit(1).pluck(:id) # exercise the database
    render plain: 'OK'
  end

end
