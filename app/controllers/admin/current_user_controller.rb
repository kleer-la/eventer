# frozen_string_literal: true

module Admin
  class CurrentUserController < AdminController
    def roles
      render json: {
        email: current_user.email,
        roles: current_user.roles.map(&:name)
      }
    end
  end
end
