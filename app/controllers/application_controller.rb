class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  def current_user
    return @current_user if defined?(@current_user)

    user_id = session[:user_id]
    @current_user = user_id ? User.find_by(id: user_id) : nil
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    redirect_to login_path, alert: "Нужно войти" unless logged_in?
  end
end