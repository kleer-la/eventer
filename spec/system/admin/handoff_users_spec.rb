# frozen_string_literal: true

require 'rails_helper'

# Who has a session-handoff account and a token (#201). Read-only, apart from
# revoking a token and deleting the account: the account is born from Google
# and the token is issued from the account's own page, never from here.
RSpec.describe 'Admin handoff users', type: :system do
  include Devise::Test::IntegrationHelpers

  before { driven_by(:rack_test) }

  let!(:handoff_user) { create(:handoff_user) }
  let!(:token) { HandoffToken.issue!(handoff_user) }

  it 'lists the accounts with their locale, token and monthly briefings' do
    TtsUsage.create!(status: 'ok', beats_count: 2, chars: 50, synthesis_ms: 100, owner_id: handoff_user.id)
    sign_in create(:admin_user)

    visit admin_handoff_users_path

    expect(page).to have_content('ana@example.com')
    expect(page).to have_content('es')
    expect(page).to have_content('Active')
    expect(page).not_to have_link('New Handoff User')
    expect(page).not_to have_content(token.plaintext)
  end

  it 'lets an administrator revoke the token' do
    sign_in create(:admin_user)

    visit admin_handoff_user_path(handoff_user)
    click_link 'Revoke token'

    expect(page).to have_content('Token revoked')
    expect(handoff_user.active_token).to be_nil
    expect(token.reload).to be_revoked
  end

  it 'shows a content user the account but not the revoke button' do
    sign_in create(:content_user)

    visit admin_handoff_user_path(handoff_user)

    expect(page).to have_content('ana@example.com')
    expect(page).not_to have_link('Revoke token')
  end

  it 'lets an administrator delete the account with its tokens and briefings, keeping usage anonymous' do
    usage = TtsUsage.create!(status: 'ok', beats_count: 2, chars: 50, synthesis_ms: 100, owner_id: handoff_user.id)
    HandoffBriefing.create!(handoff_user: handoff_user, audio: 'mp3', expires_at: 1.hour.from_now)
    sign_in create(:admin_user)

    visit admin_handoff_user_path(handoff_user)
    click_link 'Delete Handoff User'

    expect(page).to have_content('Handoff user was successfully destroyed')
    expect(HandoffUser.exists?(handoff_user.id)).to be false
    expect(HandoffToken.where(handoff_user_id: handoff_user.id)).to be_empty
    expect(HandoffBriefing.where(handoff_user_id: handoff_user.id)).to be_empty
    expect(usage.reload.owner_id).to be_nil
  end

  it 'shows a content user no delete button' do
    sign_in create(:content_user)

    visit admin_handoff_user_path(handoff_user)

    expect(page).not_to have_link('Delete Handoff User')
  end
end
