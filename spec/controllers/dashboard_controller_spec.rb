# frozen_string_literal: true

require 'rails_helper'
require './lib/country_filter'
require_relative '../support/devise'

describe DashboardController do
  describe "GET 'index'" do
    login_admin
    it 'returns http success' do
      get 'index'
      expect(response).to be_successful
    end
  end

  describe "GET 'pricing'" do
    login_admin
    it 'no event' do
      get 'pricing'
      expect(assigns(:events)).to eq []
      expect(response).to be_successful
    end
    it 'one event' do
      event = FactoryBot.create(:event, registration_link: '')
      get 'pricing'
      expect(assigns(:events)).to eq [event]
      expect(response).to be_successful
    end
  end

  describe "GET 'countdown'" do
    login_admin
    it 'no event' do
      get 'pricing'
      expect(assigns(:events)).to eq []
      expect(response).to be_successful
    end
    it 'one event' do
      event = FactoryBot.create(:event, registration_link: '')
      get 'pricing'
      expect(assigns(:events)).to eq [event]
      expect(response).to be_successful
    end
  end

  describe CountryFilter do
    before(:all) do
      c = Country.find_by_iso_code('AR')
      @ar_id = !c.nil? ? c.id : FactoryBot.create(:country).id
    end

    it 'Not select a country' do
      country_filter = CountryFilter.new('AR')
      expect(country_filter.select?(0)).to eq false
    end
    it 'Select a country' do
      country_filter = CountryFilter.new('AR')
      expect(country_filter.select?(@ar_id)).to eq true
    end
    it 'Select a country with lowercase' do
      country_filter = CountryFilter.new('ar')
      expect(country_filter.select?(@ar_id)).to eq true
    end
    it 'filter an unknown country' do
      country_filter = CountryFilter.new('xx')
      expect(country_filter.select?(@ar_id)).to eq false
    end
    context 'no filtered' do
      before(:each) do
        @country_filter = CountryFilter.new(nil)
      end
      it('.country_iso should be nil') { expect(@country_filter.country_iso).to eq nil }
      it('.select? should be true ') { expect(@country_filter.select?(1)).to eq true }
    end
    context 'filtered with all' do
      before(:each) do
        @country_filter = CountryFilter.new('all')
      end
      it('.country_iso should be nil') { expect(@country_filter.country_iso).to eq nil }
      it('.select? should be true ') { expect(@country_filter.select?(1)).to eq true }
    end
    context 'filtered with ar' do
      before(:each) do
        @country_filter = CountryFilter.new('ar')
      end
      it('.country_iso should be ar') { expect(@country_filter.country_iso).to eq 'ar' }
      it('.select? ar should be true ') { expect(@country_filter.select?(@ar_id)).to eq true }
      it('.select? x!=ar should be false ') { expect(@country_filter.select?(@ar_id + 1)).to eq false }
    end
    context 'has been filtered w/ar' do
      it('.country_iso should be ar when current filter is nil') {
        expect(CountryFilter.new(nil, 'ar').country_iso).to eq 'ar'
      }
      it('.country_iso should be nil when current filter is all') {
        expect(CountryFilter.new('all', 'ar').country_iso).to eq nil
      }
      it('.country_iso should be co when current filter is co') {
        expect(CountryFilter.new('co', 'ar').country_iso).to eq 'co'
      }
    end
    context 'has not been filtered' do
      it('.country_iso should be ar when current filter is ar') {
        expect(CountryFilter.new('ar', nil).country_iso).to eq 'ar'
      }
      it('.country_iso should be nil when current filter is all') {
        expect(CountryFilter.new('all', nil).country_iso).to eq nil
      }
    end
  end
end
