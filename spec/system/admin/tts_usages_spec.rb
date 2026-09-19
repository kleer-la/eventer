# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin TTS usage', type: :system do
  include Devise::Test::IntegrationHelpers

  before do
    driven_by(:rack_test)
    sign_in create(:admin_user)
  end

  it 'lists the usages and shows the limits with their Setting keys' do
    Setting.create!(key: 'TTS_MAX_CONCURRENCY', value: '3')
    TtsUsage.create!(status: 'ok', beats_count: 4, chars: 321, synthesis_ms: 8000, client_hash: 'abcd1234abcd1234')

    visit admin_tts_usages_path

    expect(page).to have_content('abcd1234abcd1234')
    expect(page).to have_content('321')
    expect(page).to have_content('TTS_MAX_CONCURRENCY')
    expect(page).to have_content('TTS_MAX_BRIEFINGS_PER_HOUR_PER_CLIENT')
    expect(page).not_to have_link('New TTS Usage')
  end
end
