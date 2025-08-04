# frozen_string_literal: true

module Api
  module V3
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token

      before_action :set_cors_headers

      private

      def set_cors_headers
        headers['Access-Control-Allow-Origin'] = '*'
        headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
        headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
      end
    end
  end
end
