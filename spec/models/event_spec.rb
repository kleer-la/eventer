require 'spec_helper'
include ActiveSupport

describe Event do

  before(:each) do
    @event = FactoryGirl.build(:event)
  end

  it "should be valid" do
    @event.valid?.should be true
  end

  it "should require its date" do
    @event.date = ""

    @event.valid?.should be false
  end

  it "should require its place" do
    @event.place = ""

    @event.valid?.should be false
  end

  it "should require its city" do
    @event.city = ""

    @event.valid?.should be false
  end

  it "should require its visibility_type" do
    @event.visibility_type = ""

    @event.valid?.should be false
  end

  it "should require its mode" do
    @event.mode = ""

    @event.valid?.should be false
  end

  it "should require its list_price" do
    @event.list_price = ""

    @event.valid?.should be false
  end

  it "should require its country" do
    @event.country = nil

    @event.valid?.should be false
  end

  it "should require its trainer" do
    @event.trainer = nil

    @event.valid?.should be false
  end

  it "should require its event_type" do
    @event.event_type = nil

    @event.valid?.should be false
  end

  it "should not require a future date" do
    @event.date = "31/01/2000"

    @event.valid?.should be true
  end

  it "should have a capacity greater than 0" do
    @event.capacity = 0

    @event.valid?.should be false
  end

  it "should have specific conditions" do
    @event.specific_conditions = "Participa y llevate un Kindle de regalo!"

    @event.specific_conditions.should == "Participa y llevate un Kindle de regalo!"
  end

  it "should have a flag to enable referer codes on registrations if desired" do
    @event.should_ask_for_referer_code = false

    @event.should_ask_for_referer_code.should == false
  end

  it "should not require referer code (default)" do
    @event.should_ask_for_referer_code.should == false
  end

  it "should have a flag to prevent welcome e-mail if desired" do
    @event.should_welcome_email = false

    @event.should_welcome_email.should == false
  end

  it "should send welcome e-mails (default)" do
    @event.should_welcome_email.should == true
  end

  it "Early Bird price should be smaller than List Price" do
    @event.list_price = 100
    @event.eb_price = 200

    @event.valid?.should be false
  end

  it "Early Bird date should be earlier than Event date" do
    @event.date = "31/01/3000"
    @event.eb_end_date = "31/01/3100"

    @event.valid?.should be false
  end

  it "It should return a completion percentage" do
    @event.capacity = 10

    c = FactoryGirl.create(:country)
    zi = FactoryGirl.create(:influence_zone)
    zi.country = c

    p = Participant.new({:fname => "juan", :lname => "pipo", :phone => "1234-5678", :email => "ppp@ppp.com", :influence_zone => zi })
    p.event = @event
    p.status = "C"
    p.save

    @event.completion.should == 0.1
  end

  it "It should return a 100% completion when capacity==0" do
    @event.capacity = 0
    @event.completion.should == 1
  end

  it "It should compute weeks from now" do
    today = Date.today
    @event.date = today

    @event.weeks_from(today.weeks_ago(3)).should == 3
  end

  it "It should compute weeks from now (next year)" do
    today = Date.today
    @event.date = today + 21

    @event.weeks_from(today).should == 3
  end

  it "should require a duration" do
    @event.duration = ""

    @event.valid?.should be false
  end

  it "should have a duration greater than 0" do
    @event.duration = 0

    @event.valid?.should be false
  end

  it "should require a start time" do
    @event.start_time = ""

    @event.valid?.should be false
  end

  it "should require a end time" do
    @event.end_time = ""

    @event.valid?.should be false
  end

  it "should allow a Presencial mode" do
    @event.mode = 'cl'
    @event.is_classroom?.should be true
  end

  it "should allow an OnLine mode" do
    @event.mode = 'ol'
    @event.is_online?.should be true
  end

  it "should allow a Blended Learning mode" do
    @event.mode = 'bl'
    @event.is_blended_learning?.should be true
  end

  it "should have a webinar indicator for online community events" do
    @event.mode = 'ol'
    @event.visibility_type = 'co'
    @event.is_online?.should be true
    @event.is_community_event?.should be true
    @event.is_webinar?.should be true
  end

  it "should not have a webinar indicator for online payed events" do
    @event.mode = 'ol'
    @event.visibility_type = 'pu'
    @event.is_online?.should be true
    @event.is_community_event?.should be false
    @event.is_webinar?.should be false
  end

  it "should not have a webinar indicator for classroom community events" do
    @event.mode = 'cl'
    @event.visibility_type = 'co'
    @event.is_classroom?.should be true
    @event.is_community_event?.should be true
    @event.is_webinar?.should be false
  end

  it "should have a show_pricing flag" do
    @event.show_pricing = true
    @event.show_pricing?.should be true
  end

  it "should have a time zone name" do
    @event.time_zone_name = TimeZone.all.first.name
    tz = TimeZone.new( @event.time_zone_name )
    tz.should == TimeZone.all.first
  end

  it "should have a embedded player" do
    @event.embedded_player = "hhhh"
    @event.embedded_player.should == "hhhh"
  end

  it "should have an embedded twitter search" do
    @event.twitter_embedded_search = "hhhh"
    @event.twitter_embedded_search.should == "hhhh"
  end

  it "should have a confirmed participants notification flag" do
    @event.notify_webinar_start.should be false
    @event.notify_webinar_start = true
    @event.notify_webinar_start.should be true
  end

  it "should express if a webinar was started" do
    @event.webinar_started.should be false
    @event.mode = 'ol'
    @event.visibility_type = 'co'
    @event.start_webinar!
    @event.webinar_started?.should be true
  end

  it "should express if a webinar already finished (based on end_time in time_zone)" do
    @event.mode = 'ol'
    @event.visibility_type = 'co'
    @event.start_time = Time.now-3600
    @event.end_time = Time.now+3600
    @event.start_webinar!
    @event.webinar_finished?.should be false
    @event.end_time = Time.now-3500
    @event.webinar_finished?.should be true
  end

  it "should express if a webinar already finished (based on end_time in time_zone)" do
    @event.mode = 'ol'
    @event.visibility_type = 'co'
    @event.time_zone_name = "Buenos Aires"
    @event.start_time = Time.now-3600
    @event.end_time = Time.now+3600
    @event.start_webinar!
    @event.webinar_finished?.should be false
    @event.end_time = Time.now-3500
    @event.webinar_finished?.should be true
  end

  it "should require a time zone name if event is webinar" do
    @event.time_zone_name = ""
    @event.mode = 'ol'
    @event.visibility_type = 'pu'
    @event.valid?.should be true

    @event.mode = 'ol'
    @event.visibility_type = 'co'
    @event.valid?.should be false

    @event.time_zone_name = "Buenos Aires"
    @event.valid?.should be true
  end

  it "should allow custom e-mail prices overrite" do
    @event.custom_prices_email_text = "PL: 300, EB: 200, BN: 100"
    @event.custom_prices_email_text.should == "PL: 300, EB: 200, BN: 100"
  end

  it "should have an optional monitor email" do
    @event.monitor_email = "martin.alaimo@kleer.la"
    @event.monitor_email.should == "martin.alaimo@kleer.la"
  end

  context "A private event" do

    before (:each) do
      @event.visibility_type = "pr"
    end

    it "should not have special price for early birds" do
      @event.eb_price = 1100

      @event.valid?.should be false
    end

    it "should not have special price for couples" do
      @event.couples_eb_price = 1000

      @event.valid?.should be false
    end

    it "should not have special price for business" do
      @event.business_price = 950
      @event.business_eb_price = 900

      @event.valid?.should be false
    end

    it "should not have special price for enterprises" do
      @event.enterprise_6plus_price = 850
      @event.enterprise_11plus_price = 800

      @event.valid?.should be false
    end

    it "should not be marked as community" do
      @event.is_community_event?.should be false
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

      @event.valid?.should be true
    end

    it "should not be marked as community" do
      @event.is_community_event?.should be false
    end
  end

  context "A community event" do

    before (:each) do
      @event.visibility_type = "co"
    end

    it "should be marked as community" do
      @event.is_community_event?.should be true
    end
  end

  context "When event date is 15-Jan-2015" do

    before (:each) do
      @event.date = "15/01/2015"
    end

    it "should have a human date in spanish that returns '15 Ene' if duration is 1" do
      @event.duration = 1
      @event.human_date.should == "15 Ene"
    end

    it "should have a human date in spanish that returns '15 Ene' if finish date is '15 Ene'" do
      @event.finish_date = "15/01/2015"
      @event.human_date.should == "15 Ene"
    end

    it "should have a human date in spanish that returns '15-16 Ene' if duration is 2" do
      @event.duration = 2
      @event.human_date.should == "15-16 Ene"
    end

    it "should have a human date in spanish that returns '15-16 Ene' if finish date is '16 Ene'" do
      @event.finish_date = "16/01/2015"
      @event.human_date.should == "15-16 Ene"
    end

    it "should have a human date in spanish that returns '15 Ene-14 Feb' if duration is 31" do
      @event.duration = 31
      @event.human_date.should ==  "15 Ene-14 Feb"
    end

    it "should have a human date in spanish that returns '15 Ene-14 Feb' if finish date is '14-Feb'" do
      @event.finish_date = "14/02/2015"
      @event.human_date.should ==  "15 Ene-14 Feb"
    end

  end

  context "When event date is 20-Apr-2015" do

    before (:each) do
      @event.date = "20/04/2015"
    end

    it "should have a human date in spanish that returns '20 Abr' if duration is 1" do
      @event.duration = 1
      @event.human_date.should == "20 Abr"
    end

    it "should have a human date in spanish that returns '20-22 Abr' if duration is 3" do
      @event.duration = 3
      @event.human_date.should == "20-22 Abr"
    end

    it "should have a human date in spanish that returns '20 Abr-04 May' if duration is 15" do
      @event.duration = 15
      @event.human_date.should ==  "20 Abr-4 May"
    end
  end

  it "should have a human time in English that returns 'from 9:00 to 18:00hs'" do
    @event.human_time.should == "de 09:00 a 18:00 hs"
  end

 context "When Locale is en" do
    before (:each) do
      I18n.locale=:en
    end

    it "should have a human date in English that returns '20 Abr' if duration is 1" do
      @event.date = "20/04/2015"
      @event.duration = 1
      @event.human_date.should == "Apr 20"
    end
    it "should have a human time in English that returns 'from 9:00 to 18:00hs'" do
      @event.human_time.should == "from 09:00 to 18:00 hs"
    end
  end
end
