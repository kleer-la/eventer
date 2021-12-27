# frozen_string_literal: true

require 'rails_helper'

describe 'API Categories GET /categories' do
  include Rack::Test::Methods
  def app
    Rack::Builder.parse_file('config.ru').first
  end
  context 'category list in XML' do
    before(:example) do
      @category = FactoryBot.create(:category, visible: true)
      @url = '/api/categories.xml'
      get @url
      @parsed = Nokogiri::XML(last_response.body)
    end
    it 'XML?' do
      expect(last_response.status).to eq 200
      expect(last_response.body).to start_with('<?xml')
    end

    it 'one visible category' do
      expect(@parsed.xpath('/categories/category').count).to eq 1
    end

    it 'category w/one event_type' do
      @category.event_types << FactoryBot.create(:event_type, name: 'Hello, Joe')
      @category.save!

      get @url
      parsed = Nokogiri::XML(last_response.body)

      expect(parsed.xpath('/categories/category/event-types/event-type').count).to eq 1
      expect(parsed.xpath('//event-type/name').inner_text).to eq 'Hello, Joe'
    end
  end
end
