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
  describe 'slug generation' do
    it 'removes leading and trailing spaces from the slug' do
      resource = FactoryBot.create(:resource, title_es: '  Spaced Title  ')
      expect(resource.slug).to eq('spaced-title')
    end

    it 'updates slug when title changes' do
      resource = FactoryBot.create(:resource, title_es: 'Original Title')
      expect(resource.slug).to eq('original-title')

      resource.update(slug: '', title_es: '  New Spaced Title  ')
      expect(resource.slug).to eq('new-spaced-title')
    end

    it 'maintains slug if only spaces change' do
      resource = FactoryBot.create(:resource, title_es: 'Consistent Title')
      original_slug = resource.slug

      resource.update(title_es: '  Consistent Title  ')
      expect(resource.slug).to eq(original_slug)
    end

    it 'allows slug to be edited independently of the title' do
      resource = FactoryBot.create(:resource, title_es: 'Original Title', slug: 'original-title')

      # First update just the slug
      expect(resource.update(slug: 'custom-slug')).to be true
      resource.reload # Make sure we have fresh data
      expect(resource.slug).to eq('custom-slug')

      # Then update the title
      expect(resource.update(title_es: 'New Title')).to be true
      resource.reload # Make sure we have fresh data
      expect(resource.slug).to eq('custom-slug')
    end

    it 'finds resource with both new and old slug using friendly.find' do
      resource = FactoryBot.create(:resource, title_es: 'Original Title', slug: 'original-title')
      expect(resource.slug).to eq('original-title')

      expect(resource.update(slug: 'new-title')).to be true
      resource.reload

      # Try finding with both slugs
      expect(Resource.friendly.find('original-title')).to eq(resource)
      expect(Resource.friendly.find('new-title')).to eq(resource)
    end
  end
end
