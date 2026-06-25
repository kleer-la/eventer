# frozen_string_literal: true

require 'rails_helper'

# Covers the JavaScript in app/admin/events.rb that toggles the discount/early-bird
# price fields on the event form based on visibility_type:
#   - Público (pu):   all price fields enabled
#   - Privado (pr):   discount fields disabled & cleared, list_price stays editable
#   - Comunidad (co): the whole price section is hidden
#
# This replaces the retired cucumber EB/SEB scenarios. It needs a real browser
# (the behavior is client-side JS), so it runs under headless Chrome.
RSpec.describe 'Admin event pricing visibility', type: :system do
  let(:administrator) { create(:administrator) }

  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [1400, 1400]) do |options|
      # Required for Chrome running as root in CI/containers.
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-dev-shm-usage')
    end
    # A real-browser session can't use Devise's sign_in helper (separate cookie
    # jar), so authenticate through the Devise form.
    visit new_user_session_path
    fill_in 'user_email', with: administrator.email
    fill_in 'user_password', with: 'please'
    click_button 'Identificarme'
    visit new_admin_event_path
  end

  it 'enables the discount fields for a public event' do
    choose 'Public'
    expect(page).to have_field('event_eb_price', disabled: false)
    expect(page).to have_field('event_business_price', disabled: false)
  end

  it 'disables the discount fields but keeps list price editable for a private event' do
    choose 'Private'
    expect(page).to have_field('event_eb_price', disabled: true)
    expect(page).to have_field('event_business_price', disabled: true)
    expect(page).to have_field('event_list_price', disabled: false)
  end

  it 'hides the price section for a community event' do
    choose 'Community'
    expect(page).to have_field('event_eb_price', visible: :hidden)
  end
end
