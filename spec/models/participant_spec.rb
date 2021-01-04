require 'rails_helper'

describe Participant do

  before(:each) do
    @participant = FactoryBot.build(:participant)
  end

  describe "human_status" do
    it "should be Nuevo when status is N" do
      @participant.status = "N"
      expect(@participant.human_status).to eq "Nuevo"
    end
    it "should be Presente when status is A" do
      @participant.status = "A"
      expect(@participant.human_status).to eq "Presente"
    end
  end

  describe "status_sort_order" do
    it "should be 1 when status is N" do
      expect(@participant.status_sort_order).to eq 1
    end
    it "should be 4 when status is A" do
      @participant.status = "A"
      expect(@participant.status_sort_order).to eq 4
    end
    it "should be 7 when status is q (unknown)" do
      @participant.status = "q"
      expect(@participant.status_sort_order).to eq 7
    end
  end


  it "should have a default status of 'N'" do
    expect(@participant.status).to eq "N"
  end

  it "should have a default payed of false" do
    expect(@participant.is_payed).to eq false
  end

  describe "valid" do
    it "should be valid" do
      expect(@participant.valid?).to be true
    end

    it "should require its name" do
      @participant.fname = ""

      expect(@participant.valid?).to be false
    end

    it "should require its last name" do
      @participant.lname = ""

      expect(@participant.valid?).to be false
    end

    it "should require its email" do
      @participant.email = ""

      expect(@participant.valid?).to be false
    end

    it "should validate the email" do
      @participant.email = "cualquiercosa"

      expect(@participant.valid?).to be false
    end

    it "should require the influence zone" do
      @participant.influence_zone = nil

      expect(@participant.valid?).to be false
    end

    it "should validate the email" do
      @participant.email = "hola@gmail.com"

      expect(@participant.valid?).to be true
    end

    it "should require its phone" do
      @participant.phone = ""

      expect(@participant.valid?).to be false
    end

    it "should be valid if there's no referer code" do
      @participant.referer_code = ""

      expect(@participant.valid?).to be true
    end

    it "should be valid if there's a referer code" do
      @participant.referer_code = "UNCODIGO"

      expect(@participant.valid?).to be true
    end
  end

  it "should let someone confirm it" do
    @participant.confirm!
    expect(@participant.status).to eq "C"
  end

  it "should let someone contact it" do
    @participant.contact!
    expect(@participant.status).to eq "T"
  end

  it "should let someone mark attended it" do
    expect(@participant.is_present?).to be false
    @participant.attend!
    expect(@participant.status).to eq "A"
    expect(@participant.is_present?).to be true
  end

  it "should have the event rating from the participant satisfaction survey" do
    @participant.event_rating = 5
    expect(@participant.event_rating).to eq 5
  end

  it "should have an event rating smaller or equal to 5" do
    @participant.event_rating = 10
    expect(@participant.valid?).to be false
  end

  it "should have an event rating greater or equal to 1" do
    @participant.event_rating = 0
    expect(@participant.valid?).to be false
  end

  it "should have the trainer rating from the participant satisfaction survey" do
    @participant.trainer_rating = 5
    expect(@participant.trainer_rating).to eq 5
  end

  it "should have an trainer rating smaller or equal to 5" do
    @participant.trainer_rating = 10
    expect(@participant.valid?).to be false
  end

  it "should have an trainer rating greater or equal to 1" do
    @participant.trainer_rating = 0
    expect(@participant.valid?).to be false
  end

  it "should have a testimony from a participant satisfaction survey" do
    @participant.testimony = "me ha gustado mucho"
    expect(@participant.testimony).to eq "me ha gustado mucho"
  end

  it "should have a promoter_score from a participant satisfaction survey" do
    @participant.promoter_score = 8
    expect(@participant.promoter_score).to eq 8
  end

  it "should have a promoter_score smaller or equal to 10" do
    @participant.promoter_score = 11
    expect(@participant.valid?).to be false
  end

  it "should have a promoter_score greater or equal to 0" do
    @participant.promoter_score = -1
    expect(@participant.valid?).to be false
  end

  context "given a PDF certificate is generated" do

    before(:all) do
      @participant_pdf = FactoryBot.build(:participant)
      @participant_pdf.fname= "Antonio Hiram"
      @participant_pdf.lname= "Cuéllar Valencia"
      @participant_pdf.event = FactoryBot.create(:event)
      @participant_pdf.event.event_type.csd_eligible = true
      @participant_pdf.influence_zone = FactoryBot.create(:influence_zone)
      @participant_pdf.status = "A"

      @filepath_A4 = ParticipantsHelper::generate_certificate(@participant_pdf, "A4")
      @filepath_LETTER = ParticipantsHelper::generate_certificate(@participant_pdf, "LETTER")
    end

    before(:each) do

      @reader_A4 = PDF::Reader.new(@filepath_A4)
      @reader_LETTER = PDF::Reader.new(@filepath_LETTER)

    end

    it "basic generate cert should works wo/errors" do
      allow(ParticipantsHelper).to receive(:upload_certificate).and_return('')
      rslt= @participant_pdf.generate_certificate
      expect(rslt.count).to eq 2
    end

    it "should have a unique name" do
      expect(@filepath_A4).to eq "#{Rails.root}/tmp/#{@participant_pdf.verification_code}p#{@participant_pdf.id}-A4.pdf"
      expect(@filepath_LETTER).to eq "#{Rails.root}/tmp/#{@participant_pdf.verification_code}p#{@participant_pdf.id}-LETTER.pdf"
    end

    # it "should have left a temp file in A4 format" do
    #   File.exist?(@filepath_A4).should be_true
    # end

    # it "should have left a temp file in LETTER format" do
    #   File.exist?(@filepath_LETTER).should be_true
    # end

    it "should be a single page certificate" do
      expect(@reader_A4.page_count).to eq 1
      expect(@reader_LETTER.page_count).to eq 1
    end

  end

  # context "given a batch load" do

  #   before(:each) do
  #     @event = FactoryBot.create(:event)
  #     @influence_zone = FactoryBot.create(:influence_zone)
  #     @status = "A"
  #   end

  #   it "sould allow a participant to be created from a batch line using commas" do
  #     participant_data_line = "Alaimo, Martin, malaimo@gmail.com, 1234-5678"

  #     Participant.create_from_batch_line( participant_data_line, @event, @influence_zone, @status ).should be true

  #     Participant.all.count.should == 1
  #     created_participant = Participant.first
  #     created_participant.fname.should == "Martin"
  #     created_participant.lname.should == "Alaimo"
  #     created_participant.email.should == "malaimo@gmail.com"
  #     created_participant.phone.should == "1234-5678"
  #   end

  #   it "sould allow a participant to be created from a batch line using tabs" do
  #     participant_data_line = "Alaimo\tMartin\tmalaimo@gmail.com\t1234-5678"

  #     Participant.create_from_batch_line( participant_data_line, @event, @influence_zone, @status ).should be true

  #     Participant.all.count.should == 1
  #     created_participant = Participant.first
  #     created_participant.fname.should == "Martin"
  #     created_participant.lname.should == "Alaimo"
  #     created_participant.email.should == "malaimo@gmail.com"
  #     created_participant.phone.should == "1234-5678"
  #   end

  #   it "sould allow a participant to be created from a batch line without a telephone number" do
  #     participant_data_line = "Alaimo\tMartin\tmalaimo@gmail.com"

  #     Participant.create_from_batch_line( participant_data_line, @event, @influence_zone, @status ).should be true
  #     Participant.all.count.should == 1
  #     Participant.first.phone.should == "N/A"
  #   end

  #   it "sould not allow a participant to be created from a batch line without fname" do
  #     participant_data_line = "Alaimo,,malaimo@gmail.com"

  #     Participant.create_from_batch_line( participant_data_line, @event, @influence_zone, @status ).should be false
  #     Participant.all.count.should == 0
  #   end

  #   it "sould not allow a participant to be created from a batch line without lname" do
  #     participant_data_line = ",Martin,malaimo@gmail.com"

  #     Participant.create_from_batch_line( participant_data_line, @event, @influence_zone, @status ).should be false
  #     Participant.all.count.should == 0
  #   end

  #   it "sould not allow a participant to be created from a batch line with a malformed e-mail" do
  #     participant_data_line = "Alaimo, Martin, ksjdhaSDJHasf"

  #     Participant.create_from_batch_line( participant_data_line, @event, @influence_zone, @status ).should be false
  #     Participant.all.count.should == 0
  #   end

  #   it "sould not allow a participant to be created from a batch line with less than 3 parameters" do
  #     participant_data_line = "Alaimo, Martin"

  #     Participant.create_from_batch_line( participant_data_line, @event, @influence_zone, @status ).should be false
  #     Participant.all.count.should == 0
  #   end

  # end

  # context 'search' do
  #   before(:all) do
  #     valid_attributes= {
  #         :event_id => FactoryBot.create(:event).id,
  #         :fname => "Pablo",
  #         :lname => "Picasso",
  #         :email => "ppicaso@pintores.org",
  #         :phone => "1234-5678",
  #         :influence_zone_id => FactoryBot.create(:influence_zone).id
  #       }
  #     @participant = Participant.create! valid_attributes
  #   end
  #   it 'By last name' do
  #     found= Participant.search 'Pica'
  #     found.count.should == 1
  #     found[0].lname.should == 'Picasso'
  #   end
  #   it 'Not found' do
  #     found= Participant.search 'Ramanaya'
  #     found.should eq([])
  #   end
  #   it 'By first name' do
  #     found= Participant.search 'Pabl'
  #     found.count.should == 1
  #     found[0].lname.should == 'Picasso'
  #   end
  #   it 'By first name lowercase' do
  #     found= Participant.search 'pabl'
  #     found.count.should == 1
  #     found[0].lname.should == 'Picasso'
  #   end
  # end

end
