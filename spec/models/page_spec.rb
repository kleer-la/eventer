# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Page, type: :model do
  describe 'home pages' do
    let!(:en_home) { Page.create(name: 'Home', lang: :en, slug: nil) }
    let!(:sp_home) { Page.create(name: 'home', lang: :sp, slug: nil) }

    it 'allows creation of home pages with nil slugs' do
      expect(en_home).to be_valid
      expect(sp_home).to be_valid
    end

    it 'identifies home pages correctly' do
      expect(en_home.home_page?).to be true
      expect(sp_home.home_page?).to be true
    end

    it 'generates correct to_param for home pages' do
      expect(en_home.to_param).to eq 'en'
      expect(sp_home.to_param).to eq 'sp'
    end
  end

  describe 'regular pages' do
    let!(:en_about) { Page.create(name: 'About Us', lang: :en) }
    let!(:sp_about) { Page.create(name: 'Sobre Nosotros', lang: :sp) }

    it 'generates slugs for regular pages' do
      expect(en_about.slug).to eq 'about-us'
      expect(sp_about.slug).to eq 'sobre-nosotros'
    end

    it 'identifies regular pages correctly' do
      expect(en_about.home_page?).to be false
      expect(sp_about.home_page?).to be false
    end

    it 'generates correct to_param for regular pages' do
      expect(en_about.to_param).to eq 'en-about-us'
      expect(sp_about.to_param).to eq 'sp-sobre-nosotros'
    end

    it 'allows pages with the same slug in different languages' do
      en_contact = Page.create(name: 'Contact', lang: :en)
      sp_contact = Page.create(name: 'Contact', lang: :sp)
      expect(en_contact).to be_valid
      expect(sp_contact).to be_valid
      expect(en_contact.slug).to eq 'contact'
      expect(sp_contact.slug).to eq 'contact'
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
      Page.create(name: 'Home', lang: :sp, slug: nil)
      Page.create(name: 'About', lang: :en)
      Page.create(name: 'Sobre', lang: :sp)
    end

    it 'filters pages by language' do
      expect(Page.en.count).to eq 2
      expect(Page.sp.count).to eq 2
    end
  end
end
