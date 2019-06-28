class ApplicationController < ActionController::Base

  include SessionsHelper

  def signed_in_user
    unless signed_in?
      store_location
      redirect_to signin_url, notice: 'Please log in.'
    end
  end

end
