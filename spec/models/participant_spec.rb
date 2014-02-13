require 'spec_helper'

describe Participant do
  
  before(:each) do
    @participant = FactoryGirl.build(:participant)
  end
  
  it "should be valid" do
    @participant.valid?.should be true
  end
  
  it "should have a default status of 'N'" do
    @participant.status.should == "N"
  end
  
  it "should require its name" do
    @participant.fname = ""
    
    @participant.valid?.should be false
  end
  
  it "should require its last name" do
    @participant.lname = ""
    
    @participant.valid?.should be false
  end
  
  it "should require its email" do
    @participant.email = ""
    
    @participant.valid?.should be false
  end
  
  it "should validate the email" do
    @participant.email = "cualquiercosa"
    
    @participant.valid?.should be false
  end

  it "should require the influence zone" do
    @participant.influence_zone = nil
    
    @participant.valid?.should be false
  end

  it "should validate the email" do
    @participant.email = "hola@gmail.com"
    
    @participant.valid?.should be true
  end  
  
  it "should require its phone" do
    @participant.phone = ""
    
    @participant.valid?.should be false
  end
  
  it "should be valid if there's no referer code" do
    @participant.referer_code = ""
    
    @participant.valid?.should be true
  end
  
  it "should be valid if there's a referer code" do
    @participant.referer_code = "UNCODIGO"
    
    @participant.valid?.should be true
  end
  
  it "should let someone confirm it" do
    @participant.confirm!
    @participant.status.should == "C"
  end
  
  it "should let someone contact it" do
    @participant.contact!
    @participant.status.should == "T"
  end
  
  it "should let someone mark attended it" do
    @participant.is_present?.should be false
    @participant.attend!
    @participant.status.should == "A"
    @participant.is_present?.should be true
  end
  
end
