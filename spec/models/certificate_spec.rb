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
    @participant = FactoryGirl.build(:participant)
    @et = FactoryGirl.build(:event_type)
    @e = FactoryGirl.build(:event)
    @e.event_type = @et
    @participant.event = @e
  end

    it 'should return name+last name' do
        @participant.fname = "Pepe"
        @participant.lname = "Grillo"

        cert = Certificate.new(@participant)
        cert.name.should == "Pepe Grillo"
    end

    it "should return the unique verification code" do
        cert = Certificate.new(@participant)
        cert.verification_code.should == "065BECBA36F903CF6PPP"
    end

    it 'should return false if not csd eligible' do
        @et.csd_eligible =false

        cert = Certificate.new(@participant)
        cert.is_csd_eligible?.should be false
    end
    
    it 'should return the event name' do
        @et.name = 'Pinocchio'

        cert = Certificate.new(@participant)
        cert.event_name.should == "Pinocchio"
    end

    it 'should return the event city' do
        @e.city = 'Tandil'

        cert = Certificate.new(@participant)
        cert.event_city.should == "Tandil"
    end

    it 'should return the event country' do
        cert = Certificate.new(@participant)
        cert.event_country.should == "Argentina"
    end

    it "should return the event human readable date" do
        @e.date = Date.new(2014,3,20)
        cert = Certificate.new(@participant)
        cert.event_date.should == "20-21 Mar"
    end

    it "should return the event year" do
        @e.date = Date.new(2014,3,20)
        cert = Certificate.new(@participant)
        cert.event_year.should == "2014"
    end

    it "a 16 hs event is a 2 days event" do
        @et.duration = 16
        cert = Certificate.new(@participant)
        cert.event_duration.should == "2 days"
    end

    it "a 2 hs event is a 2 hours event" do
        @et.duration = 2
        cert = Certificate.new(@participant)
        cert.event_duration.should == "2 hours"
    end

    it "a 1 hs event is a 1 hour event" do
        @et.duration = 1
        cert = Certificate.new(@participant)
        cert.event_duration.should == "1 hour"
    end

    it "should return the trainer name" do
        cert = Certificate.new(@participant)
        cert.trainer.should == "Juan Alberto"    
    end

    it "should return the trainer credentials" do
        cert = Certificate.new(@participant)
        cert.trainer_credentials.should == "Agile Coach & Trainer"    
    end

    it "should return the trainer signature image" do
        cert = Certificate.new(@participant)
        cert.trainer_signature.should == "PT.png"    
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
        certificate = Certificate.new(FactoryGirl.build(:participant))

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

        p = FactoryGirl.build(:participant)
        et = FactoryGirl.build(:event_type)
        e = FactoryGirl.build(:event)
        e.event_type = et
        p.event = e
        et.csd_eligible = true

        certificate = Certificate.new(p)

        expect(pdf).to receive(:text).exactly(9).times

        filename= ParticipantsHelper::render_certificate( pdf, certificate, "A4" )
    end

    it "csd certificate for a 3 days " do
        pdf = PrawnMock.new

        p = FactoryGirl.build(:participant)
        et = FactoryGirl.build(:event_type)
        et.duration = 24
        e = FactoryGirl.build(:event)
        e.event_type = et
        p.event = e
        et.csd_eligible = true

        certificate = Certificate.new(p)
        filename= ParticipantsHelper::render_certificate( pdf, certificate, "A4" )

        pdf.history.should include "duration of 3"
    end
    end
