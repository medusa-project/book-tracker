class ApplicationController < ActionController::Base

  include SessionsHelper

  def signed_in_user
    unless signed_in?
      store_location
      redirect_to signin_url, notice: 'Please log in.'
    end
  end

  ##
  # Sends an Enumerable in chunks as an attachment.
  #
  def stream(enumerable, filename, content_type)
    self.response.headers['X-Accel-Buffering'] = 'no'
    self.response.headers['Cache-Control'] ||= 'no-cache'
    self.response.headers['Content-Disposition'] = "attachment; filename=#{filename}"
    self.response.headers['Content-Type'] = content_type
    self.response.headers.delete('Content-Length')
    self.response_body = enumerable
  end

end
