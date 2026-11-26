# frozen_string_literal: true

require 'rails_helper'

# What each overlay template of the website reads, as the website publishes it
# (website17's /page-templates.json, kleer-la/eventer#243).
RSpec.describe WebsitePageTemplates do
  let(:url) { 'https://site.example/page-templates.json' }
  let(:body) { { templates: [{ slug: nil, sections: { hero: 'Home hero' } }, { slug: 'recursos', sections: {} }] } }

  around do |example|
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original
  end

  it 'reads the templates by slug, the home page under nil' do
    stub_request(:get, url).to_return(status: 200, body: body.to_json)

    expect(described_class.fetch(website_url: 'https://site.example'))
      .to eq(nil => { 'hero' => 'Home hero' }, 'recursos' => {})
  end

  it 'asks the website once, until the website cache is refreshed' do
    stub_request(:get, url).to_return(status: 200, body: body.to_json)

    2.times { described_class.fetch(website_url: 'https://site.example') }
    expect(a_request(:get, url)).to have_been_made.once

    described_class.clear(website_url: 'https://site.example')
    described_class.fetch(website_url: 'https://site.example')
    expect(a_request(:get, url)).to have_been_made.twice
  end

  it 'answers nil, and keeps asking, while the website does not answer' do
    stub_request(:get, url).to_return(status: 503).then.to_return(status: 200, body: body.to_json)

    expect(described_class.fetch(website_url: 'https://site.example')).to be_nil
    expect(described_class.fetch(website_url: 'https://site.example')).to include('recursos' => {})
  end

  it 'answers nil when the website is not configured' do
    expect(described_class.fetch(website_url: nil)).to be_nil
  end

  it 'is cleared when the website is told to refresh its cache' do
    allow(described_class).to receive(:clear)
    stub_request(:get, %r{site\.example/cache-reset}).to_return(status: 200)

    WebsiteCacheReset.new(website_url: 'https://site.example', token: 'tok',
                          stamp_path: Rails.root.join('tmp/spec_cache_reset_stamp')).call(force: true)

    expect(described_class).to have_received(:clear)
  end
end
