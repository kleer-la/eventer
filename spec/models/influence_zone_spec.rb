require 'rails_helper'

describe InfluenceZone do
  
  context 'valid' do
    before(:each) do
      @zi = FactoryBot.build(:influence_zone)
    end
  
    it "should be valid" do
      expect(@zi.valid?).to be true
    end

    it "should not require a zone name" do
      @zi.zone_name = ""

      expect(@zi.valid?).to be true
    end

    it "should require a tag name" do
      @zi.tag_name = ""

      expect(@zi.valid?).to be false
    end

    it "should require a country" do
      @zi.country = nil

      expect(@zi.valid?).to be false
    end
  end
  
  context "for Argentina" do
    before(:each) do
      @zi = FactoryBot.create(:influence_zone)
    end
  
    it "display_name should be 'Argentina' if zone_name = ''" do
      @zi.zone_name = ""
      
      expect(@zi.display_name).to eq "Argentina"
    end
  
    it "display_name should be 'Argentina - Buenos Aires' if zone_name = 'Buenos Aires'" do
      @zi.zone_name = "Buenos Aires"
      
      expect(@zi.display_name).to eq "Argentina - Buenos Aires"
    end
  
  end

  context "find by country" do
    before(:each) do
      @zi = FactoryBot.create(:influence_zone)
    end

    it "should find a InfluenceZone" do
      @zi.save
      iso_code= @zi.country.iso_code
  
      expect(InfluenceZone::find_by_country(iso_code).display_name).to eq @zi.display_name
    end
  
    it "no InfluenceZone for country ZZ" do
      @zi.save  
      expect(InfluenceZone::find_by_country('ZZ')).to eq nil
    end
  
  end

end
