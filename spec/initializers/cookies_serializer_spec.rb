# frozen_string_literal: true

require 'rails_helper'

# Brakeman CookieSerialization: :hybrid still reads Marshal cookies, which can
# run code if secret_key_base ever leaks. JSON only reads JSON.
RSpec.describe 'Cookie serializer' do
  it 'is JSON' do
    expect(Rails.application.config.action_dispatch.cookies_serializer).to eq(:json)
  end
end
