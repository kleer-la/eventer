# frozen_string_literal: true

require 'rails_helper'

# The session-handoff account page (#201): sign in with Google, get a personal
# TTS token, and never reach the admin.
RSpec.describe 'Handoff account', type: :system do
  before do
    driven_by(:rack_test)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = google_auth('ana@example.com', verified: true)
  end

  after { OmniAuth.config.mock_auth[:google_oauth2] = nil }

  # The site's download form, the way a person "requests" the resource (#203)
  def request_resource(email: 'ana@example.com', language: 'es')
    Contact.create!(trigger_type: :download_form, email: email,
                    form_data: { 'resource_slug' => 'session-handoff', 'language' => language })
  end

  def google_auth(email, verified:)
    OmniAuth::AuthHash.new(
      provider: 'google_oauth2', uid: "uid-#{email}",
      info: { email: email, name: 'Ana', email_verified: verified },
      extra: { raw_info: { email_verified: verified } }
    )
  end

  def sign_in_with_google(requested: true)
    request_resource if requested
    visit handoff_sign_in_path
    click_button 'Continuar con Google'
  end

  it 'asks to sign in with Google before showing the account' do
    visit handoff_path

    expect(page).to have_current_path(handoff_sign_in_path)
    expect(page).to have_button('Continuar con Google')
  end

  it 'creates the account on first sign in and shows the email' do
    expect { sign_in_with_google }.to change(HandoffUser, :count).by(1)

    expect(page).to have_current_path(handoff_path)
    expect(page).to have_content('ana@example.com')
    expect(page).to have_button('Generar token')
  end

  it 'reuses the account on the next sign in' do
    sign_in_with_google
    click_button 'Salir'

    expect { sign_in_with_google }.not_to change(HandoffUser, :count)
  end

  it 'refuses an unverified Google email' do
    OmniAuth.config.mock_auth[:google_oauth2] = google_auth('nadie@example.com', verified: false)

    expect { sign_in_with_google }.not_to change(HandoffUser, :count)
    expect(page).to have_current_path(handoff_sign_in_path)
    expect(page).to have_content('verificad')
  end

  it 'shows a new token once, then only that it exists' do
    sign_in_with_google
    click_button 'Generar token'

    token = page.find('code#handoff-token').text
    expect(token).to start_with('kh_')
    expect(page).to have_content("SESSION_HANDOFF_TTS_TOKEN=#{token}")

    visit handoff_path
    expect(page).not_to have_content(token)
    expect(page).to have_button('Regenerar token')
    expect(page).to have_button('Revocar token')
  end

  it 'regenerates and revokes' do
    sign_in_with_google
    click_button 'Generar token'
    first_token = page.find('code#handoff-token').text

    click_button 'Regenerar token'
    expect(page.find('code#handoff-token').text).not_to eq first_token
    expect(HandoffToken.authenticate(first_token)).to be_nil

    click_button 'Revocar token'
    expect(page).to have_button('Generar token')
    expect(HandoffToken.active.count).to eq 0
  end

  it 'shows this month usage against the quota' do
    sign_in_with_google
    TtsUsage.create!(status: 'ok', beats_count: 3, chars: 100, owner_id: HandoffUser.last.id)

    visit handoff_path

    expect(page).to have_content("1 de #{TtsUsage::DEFAULT_MAX_BRIEFINGS_PER_MONTH_PER_USER}")
  end

  it 'shows the MCP connector URL' do
    sign_in_with_google

    expect(page).to have_content('/handoff/mcp')
  end

  it 'refuses someone who never requested the resource, pointing at the form' do
    expect { sign_in_with_google(requested: false) }.not_to change(HandoffUser, :count)

    expect(page).to have_current_path(handoff_sign_in_path)
    expect(page).to have_content('ana@example.com')
    expect(page).to have_link(href: %r{/es/recursos/session-handoff\z})
  end

  it 'speaks the language the resource was requested in' do
    request_resource(language: 'en')
    visit '/handoff/en'
    expect(page).to have_button('Continue with Google')

    click_button 'Continue with Google'
    expect(page).to have_content('Your token')
    expect(HandoffUser.last.locale).to eq 'en'

    click_button 'Generate token'
    expect(page).to have_content('SESSION_HANDOFF_TTS_TOKEN=kh_')
    click_button 'Sign out'
    expect(page).to have_button('Continue with Google')
  end

  it 'answers in English on the English entry point even before signing in' do
    visit '/handoff/en'
    click_button 'Continue with Google'

    expect(page).to have_content('request')
    expect(page).to have_link(href: %r{/en/resources/session-handoff\z})
  end

  it 'does not let a handoff user into the admin' do
    sign_in_with_google

    visit admin_dashboard_path

    expect(page).to have_current_path(new_user_session_path)
  end
end
