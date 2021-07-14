require 'rails_helper'
require 'aws-sdk'
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
 
  it 'new (2021) certificate wo/file' do
    @participant.event.event_type.kleer_cert_seal_image = ''
    cert= Certificate.new(@participant)
    expect(cert.background_file).to eq 'base2021.png'
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

    describe "certificate description" do
        context "participant present" do
            it "base description" do
                cert = Certificate.new(@participant)
                expect(cert.description).to start_with "Ha"
            end
            it "description with NONE Setting is NONE" do
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_NONE, value: "1")
                cert = Certificate.new(@participant)
                expect(cert.description).to eq "1"
            end
            it "Kleer cert description w/o Setting is base description" do
                @et.is_kleer_certification= true
                cert = Certificate.new(@participant)
                expect(cert.description).to start_with "Ha"
            end
            it "Kleer cert description with NONE Setting NONE" do
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_NONE, value: "1")
                @et.is_kleer_certification= true
                cert = Certificate.new(@participant)
                expect(cert.description).to eq "1"
            end
            it "Kleer cert description with KLEER Setting is NONE" do
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_NONE, value: "1")
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_KLEER, value: "2")
                @et.is_kleer_certification= true
                cert = Certificate.new(@participant)
                expect(cert.description).to eq "1"
            end
            it "SA cert description w/o SA Setting is NONE" do
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_NONE, value: "1")
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_KLEER, value: "2")
                @et.is_kleer_certification= true
                @et.csd_eligible= true
                cert = Certificate.new(@participant)
                expect(cert.description).to eq "1"
            end
            it "SA cert description w SA Setting wo NONE setting is base" do
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_KLEER, value: "2")
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_SCRUM_ALLIANCE, value: "3")
                @et.is_kleer_certification= true
                @et.csd_eligible= true
                cert = Certificate.new(@participant)
                expect(cert.description).to start_with "Ha"
            end
            it "SA/KLEER cert description w SA/KLEER Setting is NONE" do
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_NONE, value: "1")
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_KLEER, value: "2")
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_SCRUM_ALLIANCE, value: "3")
                @et.is_kleer_certification= true
                @et.csd_eligible= true
                cert = Certificate.new(@participant)
                expect(cert.description).to eq "1"
            end
        end
        context "participant certified" do
            before(:each) do
                @participant.certify!
            end
            it "base description" do
                cert = Certificate.new(@participant)
                expect(cert.description).to start_with "Ha"
            end
            it "base description change with Setting" do
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_NONE, value: "1")
                cert = Certificate.new(@participant)
                expect(cert.description).to eq "1"
            end
            it "Kleer cert description w/o Setting is the same" do
                @et.is_kleer_certification= true
                cert = Certificate.new(@participant)
                expect(cert.description).to start_with "Ha"
            end
            it "Kleer cert description with Setting" do
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_NONE, value: "1")
                @et.is_kleer_certification= true
                cert = Certificate.new(@participant)
                expect(cert.description).to eq "1"
            end
            it "Kleer cert description w KLEER Setting is KLEER" do
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_NONE, value: "1")
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_KLEER, value: "2")
                @et.is_kleer_certification= true
                cert = Certificate.new(@participant)
                expect(cert.description).to eq "2"
            end
            it "SA cert description w/o SA Setting is NONE" do
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_NONE, value: "1")
                @et.is_kleer_certification= true
                cert = Certificate.new(@participant)
                expect(cert.description).to eq "1"
            end
            it "SA cert description w SA/KLEER Setting is KLEER" do
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_NONE, value: "1")
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_KLEER, value: "2")
                FactoryBot.create(:setting, key: ParticipantsHelper::CERTIFICATE_SCRUM_ALLIANCE, value: "3")
                @et.is_kleer_certification= true
                @et.csd_eligible= true
                cert = Certificate.new(@participant)
                expect(cert.description).to eq "2"
            end
        end
    end
    
    describe 'OnLine' do
      before(:each) do
      end

      it 'the place is not OnLine' do
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
    before(:each) do
        @certificate_store= FileStoreService.createNull 
        @participant= FactoryBot.create(:participant)
    end

    it 'fail to persist a certificate file. Wrong credentials' do
        certificate_filename = ParticipantsHelper::generate_certificate( @participant, 'A4',  @certificate_store )
        expect {ParticipantsHelper::upload_certificate( 
          certificate_filename, access_key_id: 'fail', secret_access_key: 'fail')
        }.to raise_error Aws::S3::Errors::InvalidAccessKeyId
    end

    it 'new (2021) certificate file' do
        @participant.event.event_type.kleer_cert_seal_image = 'base2021.png'
        certificate_filename = ParticipantsHelper::generate_certificate( @participant, 'A4',  @certificate_store )
        expect(certificate_filename).to include "/tmp/#{@participant.verification_code}p#{@participant.id}-A4.pdf"
    end
    it 'foreground certificate file' do
        @participant.event.event_type.kleer_cert_seal_image = 'fgbase.png'
        certificate_filename = ParticipantsHelper::generate_certificate( @participant, 'A4',  @certificate_store )
        expect(certificate_filename).to include "/tmp/#{@participant.verification_code}p#{@participant.id}-A4.pdf"
    end
      
    context 'ParticipantsHelper::Certificate' do
        it 'invalid, no signature for 1st trainer' do
            @participant.event.trainers[0].signature_image= ''
            @participant.event.save!
            @participant.attend!
            @participant.save!
            expect {
                ParticipantsHelper::Certificate.new(@participant)
            }.to raise_error 'No signature available for the first trainer'
        end
        it 'valid, no signature  for 2nd trainer' do
            @participant.event.trainer2= FactoryBot.create(:trainer, name: 'pepe', signature_image: '')
            @participant.event.save!
            @participant.attend!
            @participant.save!
            expect {
                ParticipantsHelper::Certificate.new(@participant)
            }.not_to raise_error
        end
 
        it 'default Background image' do
            cert= ParticipantsHelper::Certificate.new(@participant)
            expect(cert.background_file).to eq ParticipantsHelper::DEFAULT_BACKGROUND_IMAGE
            expect(cert.foreground_file).to be nil
        end
        it 'custom Background image' do
            @participant.event.event_type.kleer_cert_seal_image = 'shamrock.png'
            
            cert= ParticipantsHelper::Certificate.new(@participant)
            expect(cert.background_file).to eq 'shamrock.png'
            expect(cert.foreground_file).to be nil
        end
        it 'custom Foreground image' do
            @participant.event.event_type.kleer_cert_seal_image = 'fgshamrock.png'
            
            cert= ParticipantsHelper::Certificate.new(@participant)
            expect(cert.background_file).to be nil
            expect(cert.foreground_file).to eq 'fgshamrock.png'
        end

        context 'Kleer Certification' do
            before(:each) do
                @participant.event.event_type.is_kleer_certification = true
            end
            it 'Present - custom image' do
                @participant.attend!
                @participant.event.event_type.kleer_cert_seal_image = 'shamrock.png'
                cert= ParticipantsHelper::Certificate.new(@participant)
                expect(cert.background_file).to eq ParticipantsHelper::DEFAULT_BACKGROUND_IMAGE
            end
            it 'Present - no custom image' do
                @participant.attend!
                @participant.event.event_type.kleer_cert_seal_image = ''
                cert= ParticipantsHelper::Certificate.new(@participant)
                expect(cert.background_file).to eq ParticipantsHelper::DEFAULT_BACKGROUND_IMAGE
            end
            it 'Certified - custom image' do
                @participant.certify!
                @participant.event.event_type.kleer_cert_seal_image = 'shamrock.png'
                cert= ParticipantsHelper::Certificate.new(@participant)
                expect(cert.background_file).to eq 'shamrock.png'
            end
            it 'Certified - no custom image' do
                @participant.certify!
                @participant.event.event_type.kleer_cert_seal_image = ''
                cert= ParticipantsHelper::Certificate.new(@participant)
                expect(cert.background_file).to eq ParticipantsHelper::DEFAULT_BACKGROUND_IMAGE
            end
        end
    end
end
