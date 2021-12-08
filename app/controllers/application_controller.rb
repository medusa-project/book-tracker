class ApplicationController < ActionController::Base

  include SessionsHelper

  protect_from_forgery with: :exception

  rescue_from StandardError, with: :error_occurred

  def handle_error(e)
    Rails.logger.error("#{e}\n#{e.backtrace.join("\n ")}")
    flash['error'] = "#{e}"
  end

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


  private

  def error_occurred(exception)
    if exception.class == ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { render "errors/error404", status: :not_found }
        format.json { render nothing: true, status: :not_found }
        format.all { render "errors/error404", status: :not_found }
      end

    else
      io = StringIO.new
      io << "Error on #{request.url}\n"
      io << "Class:   #{exception.class}\n"
      io << "Message: #{exception.message}\n"
      io << "Time:    #{Time.now.iso8601}\n"
      io << "User:    #{current_user.username}\n" if current_user
      io << "\nStack Trace:\n"
      exception.backtrace.each do |line|
        io << line
        io << "\n"
      end

      @message = io.string
      Rails.logger.warn(@message)

      unless Rails.env.development?
        notification = BookTrackerMailer.error(@message)
        notification.deliver_now
      end

      respond_to do |format|
        format.html do
          render "errors/error500",
                 status: :internal_server_error,
                 content_type: "text/html"
        end
        format.all do
          render plain: "HTTP 500 Internal Server Error",
                 status: :internal_server_error,
                 content_type: "text/plain"
        end
      end
    end
  end

end
