require 'spec_helper'
require './lib/country_filter'

describe DashboardController do

  describe "GET 'index'" do
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = FactoryGirl.create(:administrator)
      sign_in @user
    end

    # This should return the minimal set of values that should be in the session
    # in order to pass any filters (e.g. authentication) defined in
    # CategoriesController. Be sure to keep this updated too.
    def valid_session
      nil
    end

#    it "returns http success" do
#      get 'index'
#      expect(response).to be_success
#    end
  end

  describe CountryFilter do
    before(:all) do
      c= Country.find_by_iso_code('AR')
      @ar_id= !c.nil? ? c.id : FactoryGirl.create(:country).id
    end

    it "Not select a country" do
      country_filter= CountryFilter.new('AR')
      expect(country_filter.select?(0)).to eq false
    end
    it "Select a country" do
      country_filter= CountryFilter.new('AR')
      expect(country_filter.select?(@ar_id)).to eq true
    end
    it "Select a country with lowercase" do
      country_filter= CountryFilter.new('ar')
      expect(country_filter.select?(@ar_id)).to eq true
    end
    it "filter an unknown country" do
      country_filter= CountryFilter.new('xx')
      expect(country_filter.select?(@ar_id)).to eq false
    end
    context 'no filtered' do
      before(:each) do
        @country_filter= CountryFilter.new(nil)
      end
      it('.country_iso should be nil') {expect(@country_filter.country_iso).to eq nil}
      it('.select? should be true ') {expect(@country_filter.select?(1)).to eq true}
    end
    context 'filtered with all' do
      before(:each) do
        @country_filter= CountryFilter.new('all')
      end
      it('.country_iso should be nil') {expect(@country_filter.country_iso).to eq nil}
      it('.select? should be true ') {expect(@country_filter.select?(1)).to eq true}
    end
    context 'filtered with ar' do
      before(:each) do
        @country_filter= CountryFilter.new('ar')
      end
      it('.country_iso should be ar') {expect(@country_filter.country_iso).to eq 'ar'}
      it('.select? ar should be true ') {expect(@country_filter.select?(@ar_id)).to eq true}
      it('.select? x!=ar should be false ') {expect(@country_filter.select?(@ar_id+1)).to eq false}
    end
  end

end
