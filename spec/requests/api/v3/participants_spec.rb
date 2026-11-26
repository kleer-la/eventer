# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V3::Participants', type: :request do
  # It created participants without reCAPTCHA, and nothing has called it since
  # website17 stopped in Jul 2024 (#238).
  it 'no longer takes interested participants' do
    expect(Rails.application.routes.recognize_path('/api/v3/participants/interest', method: :post))
      .not_to include(action: 'interest')
  rescue ActionController::RoutingError
    # gone: what this expects
  end

  it 'still registers participants' do
    expect(Rails.application.routes.recognize_path('/api/v3/events/1/participants/register', method: :post))
      .to include(controller: 'api/v3/participants', action: 'register')
  end
end
