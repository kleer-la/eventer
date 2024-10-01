# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Page, type: :model do
  describe 'home pages' do
    let!(:en_home) { Page.create(name: 'Home', lang: :en, slug: nil) }
    let!(:es_home) { Page.create(name: 'home', lang: :es, slug: nil) }

    it 'allows creation of home pages with nil slugs' do
      expect(en_home).to be_valid
      expect(es_home).to be_valid
    end

    it 'identifies home pages correctly' do
      expect(en_home.home_page?).to be true
      expect(es_home.home_page?).to be true
    end

    it 'generates correct to_param for home pages' do
      expect(en_home.to_param).to eq 'en'
      expect(es_home.to_param).to eq 'es'
    end
  end

  describe 'regular pages' do
    let!(:en_about) { Page.create(name: 'About Us', lang: :en) }
    let!(:es_about) { Page.create(name: 'Sobre Nosotros', lang: :es) }

    it 'generates slugs for regular pages' do
      expect(en_about.slug).to eq 'about-us'
      expect(es_about.slug).to eq 'sobre-nosotros'
    end

    it 'identifies regular pages correctly' do
      expect(en_about.home_page?).to be false
      expect(es_about.home_page?).to be false
    end

    it 'generates correct to_param for regular pages' do
      expect(en_about.to_param).to eq 'en-about-us'
      expect(es_about.to_param).to eq 'es-sobre-nosotros'
    end

    it 'allows pages with the same slug in different languages' do
      en_contact = Page.create(name: 'Contact', lang: :en)
      es_contact = Page.create(name: 'Contact', lang: :es)
      expect(en_contact).to be_valid
      expect(es_contact).to be_valid
      expect(en_contact.slug).to eq 'contact'
      expect(es_contact.slug).to eq 'contact'
    end
  end

  describe 'friendly_id' do
    it 'creates a new slug if the name changes' do
      page = Page.create(name: 'Original Title', lang: :en)
      expect(page.slug).to eq 'original-title'
      page.update(name: 'New Title')
      expect(page.slug).to eq 'new-title'
    end

    it 'does not change the slug for home pages' do
      home = Page.create(name: 'Home', lang: :en, slug: nil)
      home.update(name: 'home')
      expect(home.slug).to be_nil
    end
  end

  describe 'scopes' do
    before do
      Page.create(name: 'Home', lang: :en, slug: nil)
      Page.create(name: 'Home', lang: :es, slug: nil)
      Page.create(name: 'About', lang: :en)
      Page.create(name: 'Sobre', lang: :es)
    end

    it 'filters pages by language' do
      expect(Page.en.count).to eq 2
      expect(Page.es.count).to eq 2
    end
  end

  describe '#recommended' do
    let(:page) { FactoryBot.create(:page) }
    let(:recommended_service) { FactoryBot.create(:service, name: 'Recomended', subtitle: 'For sure') }

    before do
      FactoryBot.create(:recommended_content, source: page, target: recommended_service, relevance_order: 2)
    end

    it 'returns recommended item with proper formatting' do
      recommended = page.recommended

      expect(recommended.size).to eq(1)
      expect(recommended.first['type']).to eq('service')

      expect(recommended.first['id']).to eq(recommended_service.id)
      expect(recommended.first['title']).to eq(recommended_service.name)
      expect(recommended.first['subtitle']).to eq(recommended_service.subtitle)
      expect(recommended.first['cover']).to eq(recommended_service.side_image)
    end
  end

  describe 'cover field' do
    let(:page) { Page.new(name: 'Test Page', lang: :en) }

    it 'can be created with a cover' do
      page.cover = 'https://example.com/image.jpg'
      expect(page).to be_valid
    end

    it 'can be created without a cover' do
      expect(page).to be_valid
    end

    it 'can update the cover' do
      page.save
      expect(page.update(cover: 'https://example.com/new_image.jpg')).to be true
    end
  end
end
