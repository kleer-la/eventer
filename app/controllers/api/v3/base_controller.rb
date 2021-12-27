# frozen_string_literal: true

module Api
  module V3
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token
    end
  end
end
