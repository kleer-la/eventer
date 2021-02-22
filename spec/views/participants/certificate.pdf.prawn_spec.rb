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


  context 'PdfCertificate' do
    it "seal image not found" do
      participant= FactoryBot.create(:participant)
      participant.attend!
      participant.save!
      ev= participant.event.event_type
      ev.kleer_cert_seal_image='2021.png' # to signal a 2021 version
      ev.save!
      assign(:page_size, 'LETTER')
      assign(:verification_code, participant.verification_code)
      assign(:certificate, ParticipantsHelper::Certificate.new(participant) )
      assign(:participant, participant )

      certificate_store= FileStoreService.createNull exists: {"certificate-images/2021-LETTER.png" => false}
      assign(:certificate_store, certificate_store)
      expect {
        render :template => "participants/certificate", format: :pdf
      }.to raise_error(ActionView::Template::Error,/2021/)
    end
end
end
