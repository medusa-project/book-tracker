class SessionsController < ApplicationController

  # This is contained within omniauth.
  skip_before_action :verify_authenticity_token

  ##
  # Responds to `GET/POST /auth/failure`.
  #
  def auth_failed
    message = params.dig("message") || "incorrect username and/or password"
    message = "Login failed: #{message}"
    if request.xhr?
      render plain: message, status: :unauthorized
    else
      flash['error'] = message
      return_url = session[:return_to] || session[:referer] || books_path
      session[:return_to] = session[:referer] = nil
      redirect_to return_url, allow_other_host: true
    end
  end

  ##
  # Responds to POST /auth/:provider/callback
  #
  def create 
    auth_hash = request.env['omniauth.auth']
    # session[:user_token] = auth_hash.credentials.token 
    session[:user_email] = auth_hash.info.email 
    redirect_to return_url 
  end

  def developer
    auth_hash = request.env['omniauth.auth'] 
    if auth_hash and auth_hash[:uid]
      username = auth_hash[:uid].split('@').first
      user = User.new.tap do |u|
        u.username = username
      end
      # `admin` is used in development.
      if user.username == 'admin' or user.medusa_admin?
        return_url = clear_and_return_return_path
        sign_in user
        redirect_to return_url
        return
      end
    end
    flash['error'] = sprintf('Sign-in failed. Ensure that you are a member '\
                             'of the %s AD group.',
                             ::Configuration.instance.medusa_admins_group)
    redirect_to root_url
  end

  def destroy
    sign_out
    redirect_to root_url
  end


  protected

  def clear_and_return_return_path
    return_url = session[:return_to] || session[:referer] || books_path
    session[:return_to] = session[:referer] = nil
    reset_session
    return_url
  end

end
