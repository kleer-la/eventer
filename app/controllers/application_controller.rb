# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery
  respond_to :html, :json, :xml

  # active admin authentication
  def authenticate_admin_user!
    redirect_to new_user_session_path unless current_user.role? :administrator
  end

  # cancancan authorization
  def access_denied(exception)
    redirect_to admin_dashboard_path, alert: exception.message
  end
end
