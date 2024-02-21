# frozen_string_literal: true

require 'rails_helper'

describe Event do
  include ActiveSupport
  before(:each) do
    @event = FactoryBot.build(:event)
  end

  context 'Valid' do
    it 'should be valid' do
      expect(@event.valid?).to be true
    end

    it 'should require its date' do
      @event.date = ''

      expect(@event.valid?).to be false
    end
    it 'should require its trainer' do
      @event.trainer = nil

      expect(@event.valid?).to be false
    end

    it 'should require its place' do
      @event.place = ''

      expect(@event.valid?).to be false
    end

    it 'should require its city' do
      @event.city = ''

      expect(@event.valid?).to be false
    end

    it 'should require its visibility_type' do
      @event.visibility_type = ''

      expect(@event.valid?).to be false
    end

    it 'should require its mode' do
      @event.mode = ''

      expect(@event.valid?).to be false
    end

    it 'ol w/o time_zone not valid' do
      @event.mode = 'ol'

      expect(@event.valid?).to be false
    end

    it 'ol requieres time_zone' do
      @event.mode = 'ol'
      @event.time_zone_name = 'Hawaii'

      expect(@event.valid?).to be true
    end

    it 'should require its list_price' do
      @event.list_price = ''

      expect(@event.valid?).to be false
    end

    it 'should require its country' do
      @event.country = nil

      expect(@event.valid?).to be false
    end

    it 'should require its event_type' do
      @event.event_type = nil

      expect(@event.valid?).to be false
    end

    it 'should not require a future date' do
      @event.date = '31/01/2000'

      expect(@event.valid?).to be true
    end

    it 'registration_ends should be before event date' do
      expect { 
        FactoryBot.create(:event, date: Date.today, registration_ends: Date.today+1)
      }.to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.to_s).to include 'Registration ends' }
    end

    it 'should have a capacity greater than 0' do
      @event.capacity = 0

      expect(@event.valid?).to be false
    end
  end

  context 'has attributes' do
    it 'should have specific conditions' do
      @event.specific_conditions = 'Participa y llevate un Kindle de regalo!'

      expect(@event.specific_conditions).to eq 'Participa y llevate un Kindle de regalo!'
    end

    it 'should have a flag to enable referer codes on registrations if desired' do
      @event.should_ask_for_referer_code = false

      expect(@event.should_ask_for_referer_code).to be false
    end

    it 'should not require referer code (default)' do
      expect(@event.should_ask_for_referer_code).to be false
    end

    it 'should have a flag to prevent welcome e-mail if desired' do
      @event.should_welcome_email = false

      expect(@event.should_welcome_email).to be false
    end

    it 'should send welcome e-mails (default)' do
      expect(@event.should_welcome_email).to be true
    end

    it 'Early Bird price should be smaller than List Price' do
      @event.list_price = 100
      @event.eb_price = 200

      expect(@event.valid?).to be false
    end

    it 'Early Bird date should be earlier than Event date' do
      @event.date = '31/01/3000'
      @event.eb_end_date = '31/01/3100'

      expect(@event.valid?).to be false
    end

    it 'It should compute weeks from now' do
      today = Date.today
      @event.date = today

      expect(@event.weeks_from(today.weeks_ago(3))).to eq 3
    end

    it 'It should compute weeks from now (next year)' do
      today = Date.today
      @event.date = today + 21

      expect(@event.weeks_from(today)).to eq 3
    end

    it 'should require a duration' do
      @event.duration = ''

      expect(@event.valid?).to be false
    end

    it 'should have a duration greater than 0' do
      @event.duration = 0

      expect(@event.valid?).to be false
    end

    it 'should require a start time' do
      @event.start_time = ''

      expect(@event.valid?).to be false
    end

    it 'should require a end time' do
      @event.end_time = ''

      expect(@event.valid?).to be false
    end

    it 'should allow a Presencial mode' do
      @event.mode = 'cl'
      expect(@event.classroom?).to be true
    end

    it 'should allow an OnLine mode' do
      @event.mode = 'ol'
      expect(@event.online?).to be true
    end

    it 'should allow a Blended Learning mode' do
      @event.mode = 'bl'
      expect(@event.blended_learning?).to be true
    end

    it 'should have a show_pricing flag' do
      @event.show_pricing = true
      expect(@event.show_pricing?).to be true
    end

    it 'should have a time zone name' do
      @event.time_zone_name = ActiveSupport::TimeZone.all.first.name
      tz = ActiveSupport::TimeZone.new(@event.time_zone_name)
      expect(tz).to eq ActiveSupport::TimeZone.all.first
    end

    it 'should have a embedded player' do
      @event.embedded_player = 'hhhh'
      expect(@event.embedded_player).to eq 'hhhh'
    end

    it 'should have an embedded twitter search' do
      @event.twitter_embedded_search = 'hhhh'
      expect(@event.twitter_embedded_search).to eq 'hhhh'
    end

    it 'should allow custom e-mail prices overrite' do
      @event.custom_prices_email_text = 'PL: 300, EB: 200, BN: 100'
      expect(@event.custom_prices_email_text).to eq 'PL: 300, EB: 200, BN: 100'
    end

    it 'should have an optional monitor email' do
      @event.monitor_email = 'martin.alaimo@kleer.la'
      expect(@event.monitor_email).to eq 'martin.alaimo@kleer.la'
    end

    it 'should allow a banner text to be displayes promptly' do
      @event.banner_text = 'Un texto a ser resaltado'
      expect(@event.banner_text).to eq 'Un texto a ser resaltado'
    end

    it 'should allow a banner type' do
      @event.banner_type = 'info'
      expect(@event.banner_type).to eq 'info'
    end

    it "should have a human time in Spanish that returns 'de 9:00 to 18:00hs'" do
      I18n.with_locale(:es) {
        expect(@event.human_time).to eq 'de 09:00 a 18:00 hs'
      }
    end
  end

  context 'English' do
    before(:each) do
      @event.date = '15/01/2015'
    end
    it "should have a human time in English that returns 'from 9:00 to 18:00hs'" do
      I18n.with_locale(:en) {
        expect(@event.human_time).to eq 'from 09:00 to 18:00 hs'
      }
    end

    it "should have a human date in English if duration is 1" do
      @event.duration = 1
      I18n.with_locale(:en) {
        expect(@event.human_date).to eq 'Jan 15'
      }
    end

    it "should have a human date in English that returns '15 Ene' if finish date is '15 Ene'" do
      @event.finish_date = '01/02/2015'
      I18n.with_locale(:en) {
        expect(@event.human_date).to eq 'Jan 15-Feb 01'
      }
    end

   end

  context 'A private event' do
    before(:each) do
      @event.visibility_type = 'pr'
    end

    it 'should not have special price for early birds' do
      @event.eb_price = 1100

      expect(@event.valid?).to be false
    end

    it 'should not have special price for couples' do
      @event.couples_eb_price = 1000

      expect(@event.valid?).to be false
    end

    it 'should not have special price for business' do
      @event.business_price = 950
      @event.business_eb_price = 900

      expect(@event.valid?).to be false
    end

    it 'should not have special price for enterprises' do
      @event.enterprise_6plus_price = 850
      @event.enterprise_11plus_price = 800

      expect(@event.valid?).to be false
    end

    it 'should not be marked as community' do
      expect(@event.community_event?).to be false
    end
  end

  context 'A public event' do
    before(:each) do
      @event.visibility_type = 'pu'
    end

    it 'can have discounts' do
      @event.list_price = 1200
      @event.eb_price = 1100
      @event.couples_eb_price = 1000
      @event.business_price = 900
      @event.business_eb_price = 800
      @event.enterprise_6plus_price = 700
      @event.enterprise_11plus_price = 600

      expect(@event.valid?).to be true
    end

    it 'should not be marked as community' do
      expect(@event.community_event?).to be false
    end
  end

  context 'A community event' do
    before(:each) do
      @event.visibility_type = 'co'
    end

    it 'should be marked as community' do
      expect(@event.community_event?).to be true
    end
  end

  context 'When event date is 15-Jan-2015' do
    around(:each) do |example|
      I18n.locale = :es # Set to your test locale
      example.run
      I18n.locale = I18n.default_locale # Reset to default locale
    end
    before(:each) do
      @event.date = '15/01/2015'
    end

    it "should have a human date in spanish that returns '15 Ene' if duration is 1" do
      @event.duration = 1
      expect(@event.human_date).to eq '15 Ene'
    end

    it "should have a human date in spanish that returns '15 Ene' if finish date is '15 Ene'" do
      @event.finish_date = '15/01/2015'
      expect(@event.human_date).to eq '15 Ene'
    end

    it "should have a human date in spanish that returns '15-16 Ene' if duration is 2" do
      @event.duration = 2
      expect(@event.human_date).to eq '15-16 Ene'
    end

    it "should have a human date in spanish that returns '15-16 Ene' if finish date is '16 Ene'" do
      @event.finish_date = '16/01/2015'
      expect(@event.human_date).to eq '15-16 Ene'
    end

    it "should have a human date in spanish that returns '15 Ene-14 Feb' if duration is 31" do
      @event.duration = 31
      expect(@event.human_date).to eq '15 Ene-14 Feb'
    end

    it "should have a human date in spanish that returns '15 Ene-14 Feb' if finish date is '14-Feb'" do
      @event.finish_date = '14/02/2015'
      expect(@event.human_date).to eq '15 Ene-14 Feb'
    end
  end

  context 'When event date is 20-Apr-2015' do
    around(:each) do |example|
      I18n.locale = :es # Set to your test locale
      example.run
      I18n.locale = I18n.default_locale # Reset to default locale
    end
    before(:each) do
      @event.date = '20/04/2015'
    end

    it "should have a human date in spanish that returns '20 Abr' if duration is 1" do
      @event.duration = 1
      expect(@event.human_date).to eq '20 Abr'
    end

    it "should have a human date in spanish that returns '20-22 Abr' if duration is 3" do
      @event.duration = 3
      expect(@event.human_date).to eq '20-22 Abr'
    end

    it "should have a human date in spanish that returns '20 Abr-04 May' if duration is 15" do
      @event.duration = 15
      expect(@event.human_date).to eq '20 Abr-4 May'
    end
  end

  context 'human_long_date' do
    around(:each) do |example|
      I18n.locale = :es # Set to your test locale
      example.run
      I18n.locale = I18n.default_locale # Reset to default locale
    end
    before(:each) do
      @event.date = '30/12/2021'
    end
    it 'One day' do
      @event.duration = 1
      expect(@event.human_long_date).to eq '30 Dic 2021'
    end
    it 'Two days same years' do
      @event.duration = 2
      expect(@event.human_long_date).to eq '30-31 Dic 2021'
    end
    it 'Three days dif years' do
      @event.duration = 3
      expect(@event.human_long_date).to eq '30 Dic 2021-1 Ene 2022'
    end
  end

  context 'When Locale is en' do
    it "should have a human date in English that returns '20 Abr' if duration is 1" do
      @event.date = '20/04/2015'
      @event.duration = 1
      I18n.with_locale(:en) {
        expect(@event.human_date).to eq 'Apr 20'
      }
    end
    it "should have a human time in English that returns 'from 9:00 to 18:00hs'" do
      I18n.with_locale(:en) {
        expect(@event.human_time).to eq 'from 09:00 to 18:00 hs'
      }
    end
  end
  context 'Trainers' do
    it 'should have one trainer' do
      @event.trainer2 = nil
      expect(@event.trainers.count).to eq 1
    end
    it 'should have two trainers' do
      @event.trainer2 = FactoryBot.build(:trainer2)
      expect(@event.trainers.count).to eq 2
    end
    it 'should have three trainers' do
      @event.trainer2 = FactoryBot.build(:trainer2)
      @event.trainer3 = FactoryBot.build(:trainer2)
      expect(@event.trainers.count).to eq 3
    end
  end

  context 'Capacity' do
    it 'It should return a completion percentage w/confirmed participant' do
      @event.capacity = 10
      FactoryBot.create(:participant, event: @event, status: 'C')

      expect(@event.completion).to eq 0.1
    end

    it 'It should return a 100% completion when capacity==0' do
      @event.capacity = 0
      expect(@event.completion).to eq 1
    end
  end
  context 'Attendance' do
    it '0 attendance wo/attended or certified participant' do
      @event.capacity = 10
      FactoryBot.create(:participant, event: @event, status: 'C')

      expect(@event.attendance_counts[:attendance]).to eq 0
      expect(@event.attendance_counts[:total]).to eq 1
    end

    it '1 attendance w/ one attended participant' do
      @event.capacity = 10
      FactoryBot.create(:participant, event: @event, status: 'A')

      expect(@event.attendance_counts[:attendance]).to eq 1
      expect(@event.attendance_counts[:total]).to eq 1
    end
    it '1 attendance w/ one certified participant' do
      @event.capacity = 10
      FactoryBot.create(:participant, event: @event, status: 'K')

      expect(@event.attendance_counts[:attendance]).to eq 1
      expect(@event.attendance_counts[:total]).to eq 1
    end
  end

  context 'registration_ended?' do
    it 'Not started' do
      event = FactoryBot.create(:event, date: Date.today+10)
      expect(event.registration_ended?).to be false
    end
    it 'Started today' do
      today = Date.today
      event = FactoryBot.create(:event, date: today)
      expect(event.registration_ended? today).to be true
    end
    it 'Started yestertoday' do
      today = Date.today
      event = FactoryBot.create(:event, date: today-1)
      expect(event.registration_ended? today).to be true
    end
    it 'registration not ended' do
      event = FactoryBot.create(:event, date: Date.today+10, registration_ends: Date.today+8)
      expect(event.registration_ended?).to be false
    end
    it 'registration ended today' do
      today = Date.today
      event = FactoryBot.create(:event, date: today+1, registration_ends:today)
      expect(event.registration_ended? today).to be true
    end
    it 'registration ended yestertoday' do
      today = Date.today
      event = FactoryBot.create(:event, date: today, registration_ends:today-1)
      expect(event.registration_ended? today).to be true
    end
  end

  context 'New interested participant' do
    before(:each) do
      c = FactoryBot.create(:country, iso_code: 'AR')
      FactoryBot.create(:influence_zone, country: c)
      @event = FactoryBot.create(:event)
    end

    it 'Evething is cool' do
      expect do
        @event.interested_participant('fname', 'lname', 'e@mail.com', 'AR', 'notes')
      end.to change(Participant, :count).by(1)
    end
    it 'not cool' do
      expect do
        @result = @event.interested_participant('', '', '', 'AR', '')
      end.to change(Participant, :count).by(0)

      expect(@result).to match(/Fname/)
      expect(@result).to match(/Lname/)
      expect(@result).to match(/Email/)
    end
    it 'country not found' do
      expect do
        @result = @event.interested_participant('', '', '', 'ZZ', '')
      end.to change(Participant, :count).by(0)

      expect(@result).to match(/país/)
    end
  end

  context 'princing' do
    before(:each) do
      @eb = DateTime.new(2022, 1, 1)
      @event = FactoryBot.build(:event,
                                eb_end_date: @eb,
                                list_price: 99, eb_price: 98, couples_eb_price: 97,
                                business_price: 96, business_eb_price: 95,
                                enterprise_6plus_price: 94, enterprise_11plus_price: 93)
    end

    it 'eb date comparation wo hour' do
      expect(@event.price(1, DateTime.new(2022, 1, 1, 8))).to eq 98
    end

    context 'early bird' do
      [[1, 98],
       [2, 97],
       [3, 97],
       [4, 97],
       [5, 95],
       [6, 95],
       [7, 93]].each do |nro, unit_price|
        it "for # people #{nro} #{unit_price}" do
          expect(@event.price(nro, @eb - 1)).to eq unit_price
        end
      end
    end
    context 'same day eb is early bird price' do
      [[1, 98],
       [2, 97],
       [3, 97],
       [4, 97],
       [5, 95],
       [6, 95],
       [7, 93]].each do |nro, unit_price|
        it "for # people #{nro} #{unit_price}" do
          expect(@event.price(nro, @eb)).to eq unit_price
        end
      end
    end
    context 'regular price' do
      [[1, 99],
       [2, 99],
       [3, 99],
       [4, 99],
       [5, 96],
       [6, 96],
       [7, 94]].each do |nro, unit_price|
        it "for # people #{nro} #{unit_price}" do
          expect(@event.price(nro, @eb + 1)).to eq unit_price
        end
      end
    end
    context 'regular price w/o eb' do
      before(:each) do
        @event.eb_end_date = nil
      end

      [[1, 99],
       [2, 99],
       [3, 99],
       [4, 99],
       [5, 96],
       [6, 96],
       [7, 94]].each do |nro, unit_price|
        it "for # people #{nro} #{unit_price}" do
          expect(@event.price(nro, DateTime.new)).to eq unit_price
        end
      end
    end
  end
  describe '#ask_for_coupons_code?' do
    let(:event) { FactoryBot.create(:event, list_price: 100) }
    it { expect(event.ask_for_coupons_code?).to eq false}

    it 'codeless coupon' do
      FactoryBot.create(:coupon, coupon_type: :codeless, percent_off: 40.0)
                .event_types << event.event_type
      expect(event.ask_for_coupons_code?).to eq false
    end
    it 'percent_off coupon' do
      FactoryBot.create(:coupon, coupon_type: :percent_off, percent_off: 40.0)
                .event_types << event.event_type
      expect(event.ask_for_coupons_code?).to eq true
    end
  end
end
