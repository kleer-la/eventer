# encoding: utf-8
require 'rails_helper'

RSpec.describe "generate one certificate" do
  it "abort when no page_size" do
    render :template => "participants/certificate", format: :pdf
    texts= PDF::Inspector::Text.analyze(rendered).strings
    expect(texts[0]).to include 'LETTER'
  end
  it "abort when wrong verification code" do
    assign(:page_size, 'LETTER')
    render :template => "participants/certificate", format: :pdf
    texts= PDF::Inspector::Text.analyze(rendered).strings
    expect(texts[0]).to include 'código de verificación'
  end
  it "abort when wrong verification code" do
    participant= FactoryBot.create(:participant)
    assign(:page_size, 'LETTER')
    assign(:verification_code, participant.verification_code)
    assign(:certificate, ParticipantsHelper::Certificate.new(participant) )
    assign(:participant, participant )

    render :template => "participants/certificate", format: :pdf
    texts= PDF::Inspector::Text.analyze(rendered).strings
    expect(texts[0]).to include 'no estuvo presente'
  end

  it "a correct one@participant." do
    participant= FactoryBot.create(:participant)
    participant.attend!
    participant.save!
    trainer= participant.event.trainer
    trainer.signature_image= 'PT.png'
    assign(:page_size, 'LETTER')
    assign(:verification_code, participant.verification_code)
    assign(:certificate, ParticipantsHelper::Certificate.new(participant) )
    assign(:participant, participant )

    render :template => "participants/certificate", format: :pdf
    texts= PDF::Inspector::Text.analyze(rendered).strings
    expect(texts.join ' ').to include 'Juan Carlos Perez Luasó attended'
  end

  it 'fail to persist a certificate file. Wrong credentials' do
    participant= FactoryBot.create(:participant)
    certificate_filename = ParticipantsHelper::generate_certificate( participant, 'A4' )
    expect {ParticipantsHelper::upload_certificate( 
      certificate_filename, access_key_id: 'fail', secret_access_key: 'fail')
    }.to raise_error AWS::S3::Errors::InvalidAccessKeyId
  end
  it 'new (2020) certificate file' do
    participant= FactoryBot.create(:participant)
    participant.event.event_type.kleer_cert_seal_image = 'cert2021.png'
    certificate_filename = ParticipantsHelper::generate_certificate( participant, 'A4' )
  end
  
  context 'PdfCertificate' do
    it 'invalid, no signature  for 2nd trainer' do
      participant= FactoryBot.create(:participant)
      participant.event.trainers[0].signature_image= ''
      participant.attend!
      participant.save!
      expect {
        ParticipantsHelper::Certificate.new(participant)
      }.to raise_error 'No signature available for the first trainer'
    end
    it 'valid, no signature  for 2nd trainer' do
      participant= FactoryBot.create(:participant)
      participant.event.trainers[1]= FactoryBot.create(:trainer, signature_image: '')
      participant.attend!
      participant.save!
      expect {
        ParticipantsHelper::Certificate.new(participant)
      }.not_to raise_error
    end
  end
end
