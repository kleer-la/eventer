require 'rails_helper'

describe InfluenceZone do
  
  before(:each) do
    @zi = FactoryBot.build(:influence_zone)
  end
  
    it "should be valid" do
      expect(@zi.valid?).to be true
    end

    it "should not require its zone name" do
      @zi.zone_name = ""

      expect(@zi.valid?).to be true
    end

    it "should require its tag name" do
      @zi.tag_name = ""

      expect(@zi.valid?).to be false
    end

    it "should require its country" do
      @zi.country = nil

      expect(@zi.valid?).to be false
    end
    
    context "for Argentina" do
      
      before(:each) do
        @zi.country = FactoryBot.build(:country)
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
  
end
