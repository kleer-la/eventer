# frozen_string_literal: true

require 'rails_helper'

# The admin button and the MCP tool ask the same service; the button is the one
# that gets its way regardless of the throttle, because a person pressed it.
RSpec.describe 'Admin website cache reset', type: :feature do
  let(:administrator) { create(:administrator) }
  let(:endpoint) { 'https://site.example/cache-reset' }

  before do
    login_as(administrator, scope: :user)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('WEBSITE_URL', nil).and_return('https://site.example')
    allow(ENV).to receive(:fetch).with('CACHE_RESET_TOKEN', nil).and_return('tok')
    FileUtils.rm_f(WebsiteCacheReset::DEFAULT_STAMP_PATH)
  end

  after { FileUtils.rm_f(WebsiteCacheReset::DEFAULT_STAMP_PATH) }

  it 'refreshes the website and says so' do
    stub_request(:get, endpoint).with(query: { token: 'tok' }).to_return(status: 200)

    visit admin_cache_reset_path
    click_button 'Reset Cache'

    expect(page).to have_content('reloaded the content it had cached')
  end

  it 'refreshes again right away, unlike the MCP tool' do
    stub_request(:get, endpoint).with(query: { token: 'tok' }).to_return(status: 200)
    WebsiteCacheReset.new.call

    visit admin_cache_reset_path
    click_button 'Reset Cache'

    expect(WebMock).to have_requested(:get, endpoint).with(query: { token: 'tok' }).twice
  end

  it 'reports a website that turns the reset down' do
    stub_request(:get, endpoint).with(query: { token: 'tok' }).to_return(status: 403)

    visit admin_cache_reset_path
    click_button 'Reset Cache'

    expect(page).to have_content('403')
  end
end
