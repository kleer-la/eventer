# frozen_string_literal: true

require 'rails_helper'

# A resource that left and has an equivalent sends its visitors there: the site
# answers its URL with a 301 to redirect_url, as it does for articles (#236).
describe 'resource redirect_url' do
  let(:user) { FactoryBot.create(:content_user) }
  let(:resource) { FactoryBot.create(:resource, published: false) }

  def run(**args)
    tool = ResourcesTool.new
    allow(tool).to receive_messages(current_user: user, ability: Ability.new(user))
    JSON.parse(tool.call(**args))
  end

  describe 'model' do
    it 'accepts a path or a URL, and empty' do
      expect(build(:resource, redirect_url: '/es/recursos/otro')).to be_valid
      expect(build(:resource, redirect_url: 'https://example.com/x')).to be_valid
      expect(build(:resource, redirect_url: '')).to be_valid
    end

    it 'refuses anything else and stores empty as NULL' do
      expect(build(:resource, redirect_url: 'otro')).not_to be_valid
      expect(create(:resource, redirect_url: '  ').redirect_url).to be_nil
    end
  end

  describe 'MCP resources tool' do
    it 'warns in the preview that the URL answers 301' do
      result = run(operation: 'update', id: resource.slug, redirect_url: '/es/recursos/otro')

      expect(result['status']).to eq 'preview'
      expect(result['warnings'].join).to include('301 to /es/recursos/otro')
    end

    it 'saves it and reads it back in get and list' do
      run(operation: 'update', id: resource.slug, redirect_url: '/es/recursos/otro', confirm: true)

      expect(run(operation: 'get', id: resource.slug)['redirect_url']).to eq '/es/recursos/otro'
      expect(run(operation: 'list')['resources'].first['redirect_url']).to eq '/es/recursos/otro'
    end

    it 'suggests one when it is being unpublished without it' do
      resource.update!(published: true)
      publisher = FactoryBot.create(:publisher_user)
      tool = ResourcesTool.new
      allow(tool).to receive_messages(current_user: publisher, ability: Ability.new(publisher))

      result = JSON.parse(tool.call(operation: 'update', id: resource.slug, published: false))

      expect(result['warnings'].join).to include('redirect_url')
    end
  end
end
