# frozen_string_literal: true

require 'rails_helper'

describe Participant do
  before(:each) do
    @participant = FactoryBot.build(:participant)
  end

  describe 'human_status' do
    it 'should be Nuevo when status is N' do
      @participant.status = 'N'
      expect(@participant.human_status).to eq 'Nuevo'
    end
    it 'should be Presente when status is A' do
      @participant.status = 'A'
      expect(@participant.human_status).to eq 'Presente'
    end
    it 'should be Certified when status is K' do
      @participant.status = 'K'
      expect(@participant.human_status).to eq 'Certificado'
    end
  end

  describe 'status_sort_order' do
    it 'should be 1 when status is N' do
      expect(@participant.status_sort_order).to eq 1
    end
    it 'should be 4 when status is A' do
      @participant.status = 'A'
      expect(@participant.status_sort_order).to eq 4
    end
    it 'should be 7 when status is q (unknown)' do
      @participant.status = 'q'
      expect(@participant.status_sort_order).to eq 8
    end
  end

  describe 'create callback' do
    it 'strip fname' do
      part =  FactoryBot.create(:participant, fname: '  pepe  ')
      expect(part.fname).to eq 'pepe'
    end
    it 'strip lname' do
      part =  FactoryBot.create(:participant, lname: '  pepe  ')
      expect(part.lname).to eq 'pepe'
    end
    it 'calc company name if missing' do
      part = FactoryBot.create(:participant, fname: 'pepe', lname: 'smith')
      expect(part.company_name).to eq 'pepe smith'
    end
    it 'DONT calc company name if present' do
      part = FactoryBot.create(:participant, company_name: 'ACME')
      expect(part.company_name).to eq 'ACME'
    end
  end

  context 'default' do
    it "should have a default status of 'N'" do
      expect(@participant.status).to eq 'N'
    end

    it 'should have a default quantity of 1' do
      expect(@participant.quantity).to eq 1
    end

    it 'should have a default payed of false' do
      expect(@participant.is_payed).to eq false
    end
  end

  describe 'valid' do
    it 'should be valid' do
      expect(@participant.valid?).to be true
    end

    it 'should require its name' do
      @participant.fname = ''

      expect(@participant.valid?).to be false
    end

    it 'should require its last name' do
      @participant.lname = ''

      expect(@participant.valid?).to be false
    end

    it 'should require its email' do
      @participant.email = ''

      expect(@participant.valid?).to be false
    end

    it 'should validate the email' do
      @participant.email = 'cualquiercosa'

      expect(@participant.valid?).to be false
    end

    it 'could have no the influence zone' do
      @participant.influence_zone = nil

      expect(@participant.valid?).to be true
    end

    it 'should validate the email' do
      @participant.email = 'hola@gmail.com'

      expect(@participant.valid?).to be true
    end

    it 'phone is optional' do
      @participant.phone = ''

      expect(@participant.valid?).to be true
    end

    it "should be valid if there's NO referer code" do
      @participant.referer_code = ''

      expect(@participant.valid?).to be true
    end

    it "should be valid if there's a referer code" do
      @participant.referer_code = 'UNCODIGO'

      expect(@participant.valid?).to be true
    end

    it 'should be valid to change quantity to 2' do
      @participant.quantity = 2
      @participant.save!

      expect(@participant.quantity).to eq 2
    end
  end

  context 'status' do
    it 'should let someone confirm it' do
      @participant.confirm!
      expect(@participant.status).to eq 'C'
    end

    it 'should let someone contact it' do
      @participant.contact!
      expect(@participant.status).to eq 'T'
    end

    it 'should let someone mark attended it' do
      expect(@participant.present?).to be false
      @participant.attend!
      expect(@participant.status).to eq 'A'
      expect(@participant.present?).to be true
    end
  end

  context 'survey' do
    it 'should have the event rating from the participant satisfaction survey' do
      @participant.event_rating = 5
      expect(@participant.event_rating).to eq 5
    end

    it 'should have an event rating smaller or equal to 5' do
      @participant.event_rating = 10
      expect(@participant.valid?).to be false
    end

    it 'should have an event rating greater or equal to 1' do
      @participant.event_rating = 0
      expect(@participant.valid?).to be false
    end

    it 'should have the trainer rating from the participant satisfaction survey' do
      @participant.trainer_rating = 5
      expect(@participant.trainer_rating).to eq 5
    end

    it 'should have an trainer rating smaller or equal to 5' do
      @participant.trainer_rating = 10
      expect(@participant.valid?).to be false
    end

    it 'should have an trainer rating greater or equal to 1' do
      @participant.trainer_rating = 0
      expect(@participant.valid?).to be false
    end

    it 'should have a testimony from a participant satisfaction survey' do
      @participant.testimony = 'me ha gustado mucho'
      expect(@participant.testimony).to eq 'me ha gustado mucho'
    end

    it 'initially not selected' do
      expect(@participant.selected).to eq false
    end

    it 'can assign photo and profile url' do
      expect { @participant.photo_url = 'a' }.not_to raise_error
      expect { @participant.profile_url = 'b' }.not_to raise_error
    end

    it 'should have a promoter_score from a participant satisfaction survey' do
      @participant.promoter_score = 8
      expect(@participant.promoter_score).to eq 8
    end
    it 'should have a promoter_score smaller or equal to 10' do
      @participant.promoter_score = 11
      expect(@participant.valid?).to be false
    end

    it 'should have a promoter_score greater or equal to 0' do
      @participant.promoter_score = -1
      expect(@participant.valid?).to be false
    end
  end

  context 'given a PDF certificate is generated' do
    before(:all) do
      @participant_pdf = FactoryBot.build(:participant)
      @participant_pdf.fname = 'Antonio Hiram'
      @participant_pdf.lname = 'Cuéllar Valencia'
      @participant_pdf.event = FactoryBot.create(:event)
      @participant_pdf.event.event_type.csd_eligible = true
      @participant_pdf.influence_zone = FactoryBot.create(:influence_zone)
      @participant_pdf.status = 'A'
      store = FileStoreService.create_null
      @participant_pdf.filestore store

      @filepath_a4 = ParticipantsHelper.generate_certificate(@participant_pdf, 'A4', store)
      @filepath_letter = ParticipantsHelper.generate_certificate(@participant_pdf, 'LETTER', store)
    end

    before(:each) do
      @reader_a4 = PDF::Reader.new(@filepath_a4)
      @reader_letter = PDF::Reader.new(@filepath_letter)
    end

    it 'basic cert should works wo/errors' do
      allow(ParticipantsHelper).to receive(:upload_certificate).and_return('')
      rslt = @participant_pdf.generate_certificate
      expect(rslt.count).to eq 2
    end

    it 'should have a unique name' do
      base = "#{Rails.root}/tmp/#{@participant_pdf.verification_code}p#{@participant_pdf.id}"
      expect(@filepath_a4).to eq "#{base}-A4.pdf"
      expect(@filepath_letter).to eq "#{base}-LETTER.pdf"
    end

    it 'should be a single page certificate' do
      expect(@reader_a4.page_count).to eq 1
      expect(@reader_letter.page_count).to eq 1
    end
  end

  context 'given a batch load' do
    before(:each) do
      @event = FactoryBot.create(:event)
      @influence_zone = FactoryBot.create(:influence_zone)
      @status = 'A'
    end

    it 'sould allow a participant to be created from a batch line using commas' do
      participant_data_line = 'Alaimo, Martin, malaimo@gmail.com, 1234-5678'

      expect(
        Participant.create_from_batch_line(participant_data_line, @event, @influence_zone, @status)
      ).to be true
      expect(Participant.all.count).to eq 1

      created_participant = Participant.first
      expect(created_participant.fname).to eq 'Martin'
      expect(created_participant.lname).to eq 'Alaimo'
      expect(created_participant.email).to eq 'malaimo@gmail.com'
      expect(created_participant.phone).to eq '1234-5678'
    end

    it 'sould allow a participant to be created from a batch line using tabs' do
      participant_data_line = "Alaimo\tMartin\tmalaimo@gmail.com\t1234-5678"

      expect(
        Participant.create_from_batch_line(participant_data_line, @event, @influence_zone, @status)
      ).to be true

      expect(Participant.all.count).to eq 1
      created_participant = Participant.first
      expect(created_participant.fname).to eq 'Martin'
      expect(created_participant.lname).to eq 'Alaimo'
      expect(created_participant.email).to eq 'malaimo@gmail.com'
      expect(created_participant.phone).to eq '1234-5678'
    end

    it 'sould allow a participant to be created from a batch line without a telephone number' do
      participant_data_line = "Alaimo\tMartin\tmalaimo@gmail.com"

      expect(
        Participant.create_from_batch_line(participant_data_line, @event, @influence_zone, @status)
      ).to be true
      expect(Participant.all.count).to eq 1
      expect(Participant.first.phone).to eq 'N/A'
    end

    it 'sould not allow a participant to be created from a batch line without fname' do
      participant_data_line = 'Alaimo,,malaimo@gmail.com'

      expect(
        Participant.create_from_batch_line(participant_data_line, @event, @influence_zone, @status)
      ).to be false
      expect(Participant.all.count).to be 0
    end

    it 'sould not allow a participant to be created from a batch line without lname' do
      participant_data_line = ',Martin,malaimo@gmail.com'

      expect(
        Participant.create_from_batch_line(participant_data_line, @event, @influence_zone, @status)
      ).to be false
      expect(Participant.all.count).to be 0
    end

    it 'sould not allow a participant to be created from a batch line with a malformed e-mail' do
      participant_data_line = 'Alaimo, Martin, ksjdhaSDJHasf'

      expect(
        Participant.create_from_batch_line(participant_data_line, @event, @influence_zone, @status)
      ).to be false
      expect(Participant.all.count).to be 0
    end

    it 'sould not allow a participant to be created from a batch line with less than 3 parameters' do
      participant_data_line = 'Alaimo, Martin'

      expect(
        Participant.create_from_batch_line(participant_data_line, @event, @influence_zone, @status)
      ).to be false
      expect(Participant.all.count).to be 0
    end
  end

  context 'search' do
    before(:each) do
      @participant = FactoryBot.create(:participant,
                                       fname: 'Pablo',
                                       lname: 'Picasso',
                                       verification_code: '065BECBA36F903CF6PPP')
    end
    it 'By last name' do
      found = Participant.search 'Pica', 1, 1000
      expect(found.count).to be 1
      expect(found[0].lname).to eq 'Picasso'
    end
    it 'Not found' do
      found = Participant.search 'Ramanaya', 1, 1000
      expect(found).to eq []
    end
    it 'By first name' do
      found = Participant.search 'Pabl', 1, 1000
      expect(found.count).to eq 1
      expect(found[0].lname).to eq 'Picasso'
    end
    it 'By first name lowercase' do
      found = Participant.search 'pabl', 1, 1000
      expect(found.count).to be 1
      expect(found[0].lname).to eq 'Picasso'
    end
    it 'By verification code' do
      found = Participant.search '065BECBA36F903CF6ppp', 1, 1000
      expect(found.count).to eq 1
      expect(found[0].verification_code).to eq '065BECBA36F903CF6PPP'
    end
  end

  context 'payments' do
    before(:each) do
      @participant = FactoryBot.create(:participant,
                                       fname: 'Pedro',
                                       invoice_id: 'xanadu')
    end
    it 'exists w/invoice_id' do
      found = Participant.search_by_invoice 'xanadu'
      expect(found.fname).to eq 'Pedro'
    end
    it 'doesnt exists w/invoice_id' do
      found = Participant.search_by_invoice 'Zanadu'
      expect(found).to be nil
    end
    it 'paid? no!' do
      @participant.contact!
      expect(@participant.paid?).to be false
    end
    it 'paid? yes!' do
      @participant.contact!
      @participant.is_payed = false
      @participant.paid!
      expect(@participant.paid?).to be true
    end
  end

  describe 'certificate generation with HR notification' do
    before do
      @participant = FactoryBot.create(:participant, status: 'A')  # Present status
      allow(@participant).to receive(:generate_certificate).and_return({
        'A4' => 'http://example.com/cert_a4.pdf',
        'LETTER' => 'http://example.com/cert_letter.pdf'
      })
    end

    it 'sends certificate with HR emails and message' do
      hr_emails = ['hr@company.com', 'manager@company.com']
      hr_message = 'Congratulations on completing the training!'

      expect(EventMailer).to receive(:send_certificate_with_hr_notification)
        .with(@participant, 'http://example.com/cert_a4.pdf', 'http://example.com/cert_letter.pdf',
              hr_emails: hr_emails, hr_message: hr_message)
        .and_return(double(deliver: true))

      @participant.generate_certificate_and_notify_with_hr(
        hr_emails: hr_emails,
        hr_message: hr_message
      )
    end

    it 'sends certificate without HR info when none provided' do
      expect(EventMailer).to receive(:send_certificate_with_hr_notification)
        .with(@participant, 'http://example.com/cert_a4.pdf', 'http://example.com/cert_letter.pdf',
              hr_emails: [], hr_message: nil)
        .and_return(double(deliver: true))

      @participant.generate_certificate_and_notify_with_hr
    end
  end
end
