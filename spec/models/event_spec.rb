require 'rails_helper'
include ActiveSupport

describe Event do

  before(:each) do
    @event = FactoryBot.build(:event)
  end

  context "Valid" do
    it "should be valid" do
      expect(@event.valid?).to be true
    end

    it "should require its date" do
      @event.date = ""

      expect(@event.valid?).to be false
    end
    it "should require its trainer" do
      @event.trainer = nil

      expect(@event.valid?).to be false
    end

    it "should require its place" do
      @event.place = ""

      expect(@event.valid?).to be false
    end

    it "should require its city" do
      @event.city = ""

      expect(@event.valid?).to be false
    end

    it "should require its visibility_type" do
      @event.visibility_type = ""

      expect(@event.valid?).to be false
    end

    it "should require its mode" do
      @event.mode = ""

      expect(@event.valid?).to be false
    end

    it "should require its list_price" do
      @event.list_price = ""

      expect(@event.valid?).to be false
    end

    it "should require its country" do
      @event.country = nil

      expect(@event.valid?).to be false
    end

    it "should require its event_type" do
      @event.event_type = nil

      expect(@event.valid?).to be false
    end

    it "should not require a future date" do
      @event.date = "31/01/2000"

      expect(@event.valid?).to be true
    end

    it "should have a capacity greater than 0" do
      @event.capacity = 0

      expect(@event.valid?).to be false
    end
  end

  it "should have specific conditions" do
    @event.specific_conditions = "Participa y llevate un Kindle de regalo!"

    expect(@event.specific_conditions).to eq "Participa y llevate un Kindle de regalo!"
  end

  it "should have a flag to enable referer codes on registrations if desired" do
    @event.should_ask_for_referer_code = false

    expect(@event.should_ask_for_referer_code).to be false
  end

  it "should not require referer code (default)" do
    expect(@event.should_ask_for_referer_code).to be false
  end

  it "should have a flag to prevent welcome e-mail if desired" do
    @event.should_welcome_email = false

    expect(@event.should_welcome_email).to be false
  end

  it "should send welcome e-mails (default)" do
    expect(@event.should_welcome_email).to be true
  end

  it "Early Bird price should be smaller than List Price" do
    @event.list_price = 100
    @event.eb_price = 200

    expect(@event.valid?).to be false
  end

  it "Early Bird date should be earlier than Event date" do
    @event.date = "31/01/3000"
    @event.eb_end_date = "31/01/3100"

    expect(@event.valid?).to be false
  end

  
  it "It should compute weeks from now" do
    today = Date.today
    @event.date = today
    
    expect(@event.weeks_from(today.weeks_ago(3))).to eq 3
  end
  
  it "It should compute weeks from now (next year)" do
    today = Date.today
    @event.date = today + 21
    
    expect(@event.weeks_from(today)).to eq 3
  end
  
  it "should require a duration" do
    @event.duration = ""
    
    expect(@event.valid?).to be false
  end
  
  it "should have a duration greater than 0" do
    @event.duration = 0
    
    expect(@event.valid?).to be false
  end
  
  it "should require a start time" do
    @event.start_time = ""
    
    expect(@event.valid?).to be false
  end
  
  it "should require a end time" do
    @event.end_time = ""
    
    expect(@event.valid?).to be false
  end
  
  it "should allow a Presencial mode" do
    @event.mode = 'cl'
    expect(@event.is_classroom?).to be true
  end
  
  it "should allow an OnLine mode" do
    @event.mode = 'ol'
    expect(@event.is_online?).to be true
  end
  
  it "should allow a Blended Learning mode" do
    @event.mode = 'bl'
    expect(@event.is_blended_learning?).to be true
  end
  
  it "should have a webinar indicator for online community events" do
    @event.mode = 'ol'
    @event.visibility_type = 'co'
    expect(@event.is_online?).to be true
    expect(@event.is_community_event?).to be true
    expect(@event.is_webinar?).to be true
  end
  
  it "should not have a webinar indicator for online payed events" do
    @event.mode = 'ol'
    @event.visibility_type = 'pu'
    expect(@event.is_online?).to be true
    expect(@event.is_community_event?).to be false
    expect(@event.is_webinar?).to be false
  end
  
  it "should not have a webinar indicator for classroom community events" do
    @event.mode = 'cl'
    @event.visibility_type = 'co'
    expect(@event.is_classroom?).to be true
    expect(@event.is_community_event?).to be true
    expect(@event.is_webinar?).to be false
  end
  
  it "should have a show_pricing flag" do
    @event.show_pricing = true
    expect(@event.show_pricing?).to be true
  end
  
  it "should have a time zone name" do
    @event.time_zone_name = TimeZone.all.first.name
    tz = TimeZone.new( @event.time_zone_name )
    expect(tz).to eq TimeZone.all.first
  end
  
  it "should have a embedded player" do
    @event.embedded_player = "hhhh"
    expect(@event.embedded_player).to eq "hhhh"
  end
  
  it "should have an embedded twitter search" do
    @event.twitter_embedded_search = "hhhh"
    expect(@event.twitter_embedded_search).to eq "hhhh"
  end
  
  it "should have a confirmed participants notification flag" do
    expect(@event.notify_webinar_start).to be false
    @event.notify_webinar_start = true
    expect(@event.notify_webinar_start).to be true
  end
  
  it "should express if a webinar was started" do
    expect(@event.webinar_started).to be false
    @event.mode = 'ol'
    @event.visibility_type = 'co'
    @event.start_webinar!
    expect(@event.webinar_started?).to be true
  end
  
  it "should express if a webinar already finished (based on end_time in time_zone)" do
    @event.mode = 'ol'
    @event.visibility_type = 'co'
    @event.start_time = Time.now-3600
    @event.end_time = Time.now+3600
    @event.start_webinar!
    expect(@event.webinar_finished?).to be false
    @event.end_time = Time.now-3500
    expect(@event.webinar_finished?).to be true
  end
  
  it "should express if a webinar already finished (based on end_time in time_zone)" do
    @event.mode = 'ol'
    @event.visibility_type = 'co'
    @event.time_zone_name = "Buenos Aires"
    @event.start_time = Time.now-3600
    @event.end_time = Time.now+3600
    @event.start_webinar!
    expect(@event.webinar_finished?).to be false
    @event.end_time = Time.now-3500
    expect(@event.webinar_finished?).to be true
  end
  
  it "should require a time zone name if event is webinar" do
    @event.time_zone_name = ""
    @event.mode = 'ol'
    @event.visibility_type = 'pu'
    expect(@event.valid?).to be true
    
    @event.mode = 'ol'
    @event.visibility_type = 'co'
    expect(@event.valid?).to be false
    
    @event.time_zone_name = "Buenos Aires"
    expect(@event.valid?).to be true
  end
  
  it "should allow custom e-mail prices overrite" do
    @event.custom_prices_email_text = "PL: 300, EB: 200, BN: 100"
    expect(@event.custom_prices_email_text).to eq "PL: 300, EB: 200, BN: 100"
  end
  
  it "should have an optional monitor email" do
    @event.monitor_email = "martin.alaimo@kleer.la"
    expect(@event.monitor_email).to eq "martin.alaimo@kleer.la"
  end
  
  it "should allow a banner text to be displayes promptly" do
    @event.banner_text = "Un texto a ser resaltado"
    expect(@event.banner_text).to eq "Un texto a ser resaltado"
  end
  
  it "should allow a banner type" do
    @event.banner_type = "info"
    expect(@event.banner_type).to eq "info"
  end
  
  context "A private event" do
    
    before (:each) do
      @event.visibility_type = "pr"
    end
    
    it "should not have special price for early birds" do
      @event.eb_price = 1100
      
      expect(@event.valid?).to be false
    end
    
    it "should not have special price for couples" do
      @event.couples_eb_price = 1000
      
      expect(@event.valid?).to be false
    end
    
    it "should not have special price for business" do
      @event.business_price = 950
      @event.business_eb_price = 900
      
      expect(@event.valid?).to be false
    end
    
    it "should not have special price for enterprises" do
      @event.enterprise_6plus_price = 850
      @event.enterprise_11plus_price = 800
      
      expect(@event.valid?).to be false
    end
    
    it "should not be marked as community" do
      expect(@event.is_community_event?).to be false
    end
  end
  
  context "A public event" do
    
    before (:each) do
      @event.visibility_type = "pu"
    end
    
    it "can have discounts" do
      @event.list_price = 1200
      @event.eb_price = 1100
      @event.couples_eb_price = 1000
      @event.business_price = 900
      @event.business_eb_price = 800
      @event.enterprise_6plus_price = 700
      @event.enterprise_11plus_price = 600
      
      expect(@event.valid?).to be true
    end
    
    it "should not be marked as community" do
      expect(@event.is_community_event?).to be false
    end
  end
  
  context "A community event" do
    
    before (:each) do
      @event.visibility_type = "co"
    end
    
    it "should be marked as community" do
      expect(@event.is_community_event?).to be true
    end
  end
  
  context "When event date is 15-Jan-2015" do
    
    before (:each) do
      @event.date = "15/01/2015"
    end
    
    it "should have a human date in spanish that returns '15 Ene' if duration is 1" do
      @event.duration = 1
      expect(@event.human_date).to eq "15 Ene"
    end
    
    it "should have a human date in spanish that returns '15 Ene' if finish date is '15 Ene'" do
      @event.finish_date = "15/01/2015"
      expect(@event.human_date).to eq "15 Ene"
    end
    
    it "should have a human date in spanish that returns '15-16 Ene' if duration is 2" do
      @event.duration = 2
      expect(@event.human_date).to eq "15-16 Ene"
    end
    
    it "should have a human date in spanish that returns '15-16 Ene' if finish date is '16 Ene'" do
      @event.finish_date = "16/01/2015"
      expect(@event.human_date).to eq "15-16 Ene"
    end
    
    it "should have a human date in spanish that returns '15 Ene-14 Feb' if duration is 31" do
      @event.duration = 31
      expect(@event.human_date).to eq  "15 Ene-14 Feb"
    end
    
    it "should have a human date in spanish that returns '15 Ene-14 Feb' if finish date is '14-Feb'" do
      @event.finish_date = "14/02/2015"
      expect(@event.human_date).to eq  "15 Ene-14 Feb"
    end
    
  end
  
  context "When event date is 20-Apr-2015" do
    
    before (:each) do
      @event.date = "20/04/2015"
    end
    
    it "should have a human date in spanish that returns '20 Abr' if duration is 1" do
      @event.duration = 1
      expect(@event.human_date).to eq "20 Abr"
    end
    
    it "should have a human date in spanish that returns '20-22 Abr' if duration is 3" do
      @event.duration = 3
      expect(@event.human_date).to eq "20-22 Abr"
    end
    
    it "should have a human date in spanish that returns '20 Abr-04 May' if duration is 15" do
      @event.duration = 15
      expect(@event.human_date).to eq  "20 Abr-4 May"
    end
  end
  
  it "should have a human time in English that returns 'from 9:00 to 18:00hs'" do
    expect(@event.human_time).to eq "de 09:00 a 18:00 hs"
  end
  
  context "When Locale is en" do
    before (:each) do
      I18n.locale=:en
    end
    
    it "should have a human date in English that returns '20 Abr' if duration is 1" do
      @event.date = "20/04/2015"
      @event.duration = 1
      expect(@event.human_date).to eq "Apr 20"
    end
    it "should have a human time in English that returns 'from 9:00 to 18:00hs'" do
      expect(@event.human_time).to eq "from 09:00 to 18:00 hs"
    end
  end
  context "Trainers" do
    it "should have one trainer" do
      @event.trainer2 = nil
      expect(@event.trainers.count).to eq 1
    end
    it "should have two trainers" do
      @event.trainer2 = FactoryBot.build(:trainer2)
      expect(@event.trainers.count).to eq 2
    end
    it "should have three trainers" do
      @event.trainer2 = FactoryBot.build(:trainer2)
      @event.trainer3 = FactoryBot.build(:trainer2)
      expect(@event.trainers.count).to eq 3
    end
  end
 
  context "Capacity" do
    
    it "It should return a completion percentage w/confirmed participant" do
      @event.capacity = 10
      p= FactoryBot.create(:participant, event: @event, status: "C")
      
      expect(@event.completion).to eq 0.1
    end
    
    it "It should return a 100% completion when capacity==0" do
      @event.capacity = 0
      expect(@event.completion).to eq 1
    end
  end
end
