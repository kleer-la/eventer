# frozen_string_literal: true

require 'rails_helper'

describe 'API Categories GET /categories', type: :request do
  context 'category list in XML' do
    pending "add some examples for json to (or delete) #{__FILE__}"
    # before(:example) do
    #   @category = FactoryBot.create(:category, visible: true)
    #   @url = '/api/categories.xml'
    #   get @url
    #   @parsed = Nokogiri::XML(response.body)
    # end
    # it 'XML?' do
    #   expect(response.status).to eq 200
    #   expect(response.body).to start_with('<?xml')
    # end

    # it 'one visible category' do
    #   expect(@parsed.xpath('/categories/category').count).to eq 1
    # end

    # it 'category w/one event_type' do
    #   @category.event_types << FactoryBot.create(:event_type, name: 'Hello, Joe')
    #   @category.save!

    #   get @url
    #   parsed = Nokogiri::XML(response.body)

    #   expect(parsed.xpath('/categories/category/event-types/event-type').count).to eq 1
    #   expect(parsed.xpath('//event-type/name').inner_text).to eq 'Hello, Joe'
    # end
  end
end
