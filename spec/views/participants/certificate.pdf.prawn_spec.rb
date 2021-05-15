# encoding: utf-8
require 'rails_helper'

RSpec.describe "generate one certificate" do
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
    assign(:certificate_store, FileStoreService.createNull)

    render :template => "participants/certificate", format: :pdf
    texts= PDF::Inspector::Text.analyze(rendered).strings
    expect(texts.join ' ').to include 'Juan Carlos Perez Luasó'
  end

  context 'PdfCertificate' do
    it "seal image not found" do
      participant= FactoryBot.create(:participant)
      participant.attend!
      participant.save!
      assign(:page_size, 'LETTER')
      assign(:verification_code, participant.verification_code)
      assign(:certificate, ParticipantsHelper::Certificate.new(participant) )
      assign(:participant, participant )

      certificate_store= FileStoreService.createNull exists: {"certificate-images/base2021-LETTER.png" => false}
      assign(:certificate_store, certificate_store)
      expect {
        render :template => "participants/certificate", format: :pdf
      }.to raise_error(ActionView::Template::Error,/2021/)
    end
  end
end
