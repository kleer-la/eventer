# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Resource, type: :model do
  before(:each) do
    @resource = FactoryBot.build(:resource)
  end

  it 'create a valid instance' do
    expect(@resource.valid?).to be true
  end

  describe '#recommended' do
    let(:resource) { create(:resource) }
    let(:recommended_item) do
      create(:resource) # , external_site_url: 'https://academia.kleer.la'
    end

    before do
      RecommendedContent.create(source: resource, target: recommended_item, relevance_order: 1)
    end

    it 'returns recommended item with proper formatting' do
      recommended = resource.recommended

      expect(recommended.size).to eq(1)
      recommended_first = recommended.first

      expect(recommended_first['id']).to eq(recommended_item.id)
      expect(recommended_first['title']).to eq(recommended_item.title_es)
      expect(recommended_first['subtitle']).to eq(recommended_item.description_es)
      expect(recommended_first['cover']).to eq(recommended_item.cover_es)
      expect(recommended_first['type']).to eq('resource')
    end
  end
end
