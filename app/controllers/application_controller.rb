# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery
  respond_to :html, :json

  # active admin authentication
  def authenticate_admin_user!
    redirect_to new_user_session_path unless current_user
  end

  # cancancan authorization
  def access_denied(exception)
    message = if exception.action == :destroy
                'Only administrators can delete records.'
              else
                exception.message
              end
    redirect_back fallback_location: admin_dashboard_path, alert: message
  end
end
