# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebsiteCacheReset do
  let(:stamp_path) { Rails.root.join('tmp', "cache-reset-spec-#{SecureRandom.hex(4)}") }
  let(:endpoint) { 'https://site.example/cache-reset' }

  subject(:reset) do
    described_class.new(website_url: 'https://site.example', token: 'tok', stamp_path: stamp_path)
  end

  after { FileUtils.rm_f(stamp_path) }

  it 'asks the website to drop what it cached' do
    stub_request(:get, endpoint).with(query: { token: 'tok' }).to_return(status: 200)

    result = reset.call

    expect(result).to be_ok
    expect(result.message).to include('https://site.example')
  end

  it 'skips a second refresh that follows too closely' do
    stub_request(:get, endpoint).with(query: { token: 'tok' }).to_return(status: 200)
    reset.call

    result = reset.call

    expect(result.status).to eq(:throttled)
    expect(result.message).to match(/already refreshed/i)
    expect(WebMock).to have_requested(:get, endpoint).with(query: { token: 'tok' }).once
  end

  it 'refreshes anyway when a person asks for it' do
    stub_request(:get, endpoint).with(query: { token: 'tok' }).to_return(status: 200)
    reset.call

    expect(reset.call(force: true)).to be_ok
    expect(WebMock).to have_requested(:get, endpoint).with(query: { token: 'tok' }).twice
  end

  it 'reports what the website answered when it refuses' do
    stub_request(:get, endpoint).with(query: { token: 'tok' }).to_return(status: 403, body: 'Invalid token')

    result = reset.call

    expect(result.status).to eq(:failed)
    expect(result.message).to include('403')
  end

  it 'does not let a failed refresh start the throttle' do
    stub_request(:get, endpoint).with(query: { token: 'tok' }).to_return(status: 500)
    reset.call

    stub_request(:get, endpoint).with(query: { token: 'tok' }).to_return(status: 200)
    expect(reset.call).to be_ok
  end

  it 'reports an unreachable website instead of raising' do
    stub_request(:get, endpoint).with(query: { token: 'tok' }).to_timeout

    result = reset.call

    expect(result.status).to eq(:failed)
    expect(result.message).to be_present
  end

  it 'says so when the website is not configured' do
    result = described_class.new(website_url: nil, token: 'tok', stamp_path: stamp_path).call

    expect(result.status).to eq(:not_configured)
  end

  it 'never puts the token in what it reports' do
    stub_request(:get, endpoint).with(query: { token: 'tok' }).to_return(status: 500, body: 'nope')

    expect(reset.call.message).not_to include('tok')
  end
end
