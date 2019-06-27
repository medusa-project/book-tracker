class HealthController < ApplicationController

  ##
  # Responds to GET /health
  #
  def check
    render plain: 'OK'
  end

end
