require 'rails_helper'
include ParticipantsHelper  

class PrawnMock
    attr_reader :history

    def initialize
        @history = ""
    end
    def text(msg, options=nil)
        @history += msg
    end
    def method_missing(m,*args,&block)
    end
end

describe Certificate do

  before(:each) do
    @participant = FactoryBot.build(:participant)
    @et = FactoryBot.build(:event_type)
    @e = FactoryBot.build(:event)
    @e.event_type = @et
    @participant.event = @e
  end

    it 'should return name+last name' do
        @participant.fname = "Pepe"
        @participant.lname = "Grillo"

        cert = Certificate.new(@participant)
        expect(cert.name).to eq "Pepe Grillo"
    end

    it "should return the unique verification code" do
        cert = Certificate.new(@participant)
        expect(cert.verification_code).to eq "065BECBA36F903CF6PPP"
    end

    it 'should return false if not csd eligible' do
        @et.csd_eligible =false

        cert = Certificate.new(@participant)
        expect(cert.is_csd_eligible?).to be false
    end

    it 'should return the event name' do
        @et.name = 'Pinocchio'

        cert = Certificate.new(@participant)
        expect(cert.event_name).to eq "Pinocchio"
    end

    it 'should return the event city' do
        @e.city = 'Tandil'

        cert = Certificate.new(@participant)
        expect(cert.event_city).to eq "Tandil"
    end

    it 'should return the event country' do
        cert = Certificate.new(@participant)
        expect(cert.event_country).to eq "Argentina"
    end

    it "should return the event human readable date" do
        @e.date = Date.new(2014,3,20)
        cert = Certificate.new(@participant)
        expect(cert.event_date).to eq "20-21 Mar"
    end

    it "should return the event year" do
        @e.date = Date.new(2014,3,20)
        cert = Certificate.new(@participant)
        expect(cert.event_year).to eq "2014"
    end

    it "a 16 hs event is a 2 days event" do
        @et.duration = 16
        cert = Certificate.new(@participant)
        expect(cert.event_duration).to eq "2 days"
    end

    it "a 2 hs event is a 2 hours event" do
        @et.duration = 2
        cert = Certificate.new(@participant)
        expect(cert.event_duration).to eq "2 hours"
    end

    it "a 1 hs event is a 1 hour event" do
        @et.duration = 1
        cert = Certificate.new(@participant)
        expect(cert.event_duration).to eq "1 hour"
    end

    it "should return the trainer name" do
        cert = Certificate.new(@participant)
        expect(cert.trainer).to eq "Juan Alberto"
    end

    it "should return the trainer credentials" do
        cert = Certificate.new(@participant)
        expect(cert.trainer_credentials).to eq "Agile Coach & Trainer"
    end

    it "should return the trainer signature image" do
        cert = Certificate.new(@participant)
        expect(cert.trainer_signature).to eq "PT.png"
    end

    describe 'OnLine' do

      before(:each) do
      end

      it 'the place is OnLine' do
        cert = Certificate.new(@participant)
        expect(cert.place).to eq "Punta del Este, Argentina"
      end

      it 'the place is OnLine' do
        @participant.event.mode= 'ol'
        cert = Certificate.new(@participant)
        expect(cert.place).to eq "an OnLine course"
      end

      it "a 8 hs online event is a 8 hours event" do
          @et.duration = 8
          @participant.event.mode= 'ol'
          cert = Certificate.new(@participant)
          expect(cert.event_duration).to eq "8 hours"
      end
    end
end

describe "render certificates" do
    it "non csd certificate have 6 text lines" do
        pdf = double()
        allow(pdf).to receive(:move_down)
        allow(pdf).to receive(:image)
        allow(pdf).to receive(:bounding_box)
        allow(pdf).to receive(:line_width=)
        allow(pdf).to receive(:stroke)
        certificate = Certificate.new(FactoryBot.build(:participant))

        expect(pdf).to receive(:text).exactly(6).times

        filename= ParticipantsHelper::render_certificate( pdf, certificate, "A4" )
    end

    it "csd certificate have 9 text lines" do
        pdf = double()
        allow(pdf).to receive(:move_down)
        allow(pdf).to receive(:image)
        allow(pdf).to receive(:bounding_box)
        allow(pdf).to receive(:line_width=)
        allow(pdf).to receive(:stroke)

        p = FactoryBot.build(:participant)
        et = FactoryBot.build(:event_type)
        e = FactoryBot.build(:event)
        e.event_type = et
        p.event = e
        et.csd_eligible = true

        certificate = Certificate.new(p)

        expect(pdf).to receive(:text).exactly(9).times

        filename= ParticipantsHelper::render_certificate( pdf, certificate, "A4" )
    end

    it "csd certificate for a 3 days " do
        pdf = PrawnMock.new

        p = FactoryBot.build(:participant)
        et = FactoryBot.build(:event_type)
        et.duration = 24
        e = FactoryBot.build(:event)
        e.event_type = et
        p.event = e
        et.csd_eligible = true

        certificate = Certificate.new(p)
        filename= ParticipantsHelper::render_certificate( pdf, certificate, "A4" )

        expect(pdf.history).to include "duration of 3"
    end

    it "Render one signature" do
        t = FactoryBot.build(:trainer)
        t.signature_image = nil

        certificate = Certificate.new(p)
        expect{ParticipantsHelper::render_one_signature( nil, [0,0], t)
        }.to_not raise_error
    end

  end
