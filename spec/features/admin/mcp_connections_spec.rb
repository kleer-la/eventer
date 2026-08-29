# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin MCP Connections', type: :feature do
  let(:administrator) { create(:administrator) }
  let(:content_user) { create(:content_user) }
  let(:client) do
    Doorkeeper::Application.create!(name: 'Claude Desktop', redirect_uri: 'https://claude.ai/api/mcp/auth_callback',
                                    scopes: 'mcp', confidential: false)
  end

  def connection_for(user, expires_in: 2.hours)
    Doorkeeper::AccessToken.create!(application: client, resource_owner_id: user.id, scopes: 'mcp',
                                    expires_in: expires_in, use_refresh_token: true)
  end

  it 'lets an administrator see every connection and revoke someone else\'s' do
    mine = connection_for(administrator)
    theirs = connection_for(content_user)
    login_as(administrator, scope: :user)

    visit admin_mcp_connections_path
    expect(page).to have_content('Claude Desktop')
    expect(page).to have_content(administrator.email).and have_content(content_user.email)

    # Newest first, so the top row is the connection created last
    first(:link, 'Revoke').click

    expect(page).to have_content('Connection revoked.')
    expect(theirs.reload).to be_revoked
    expect(mine.reload).not_to be_revoked
  end

  it 'shows a non-admin only their own connections' do
    connection_for(administrator)
    connection_for(content_user)
    login_as(content_user, scope: :user)

    visit admin_mcp_connections_path
    expect(page).to have_content(content_user.email)
    expect(page).not_to have_content(administrator.email)
  end

  it 'revokes every token the client holds, so a refresh token cannot revive it' do
    first_token = connection_for(content_user)
    refreshed = connection_for(content_user)
    login_as(content_user, scope: :user)

    visit admin_mcp_connections_path
    first(:link, 'Revoke').click

    expect(first_token.reload).to be_revoked
    expect(refreshed.reload).to be_revoked
  end

  it 'marks an expired connection as expired and offers no revoke link' do
    connection_for(content_user, expires_in: -1.hour)
    login_as(content_user, scope: :user)

    visit admin_mcp_connections_path
    expect(page).to have_content('Expired')
    expect(page).to have_no_link('Revoke')
  end
end
