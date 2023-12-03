# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'generate one certificate' do
  it 'a correct one@participant.' do
    participant = FactoryBot.create(:participant)
    participant.attend!
    participant.save!
    trainer = participant.event.trainer
    trainer.signature_image = 'PT.png'
    assign(:page_size, 'LETTER')
    assign(:verification_code, participant.verification_code)
    assign(:certificate, ParticipantsHelper::Certificate.new(participant))
    assign(:participant, participant)
    assign(:certificate_store, FileStoreService.create_null)

    pdf_io = StringIO.new( render template: 'participants/certificate', format: :pdf)
    texts = PDF::Inspector::Text.analyze(pdf_io).strings

    expect(texts.join(' ')).to include 'Juan Carlos Perez Luasó'
  end

  context 'PdfCertificate' do
    it 'seal image not found' do
      participant = FactoryBot.create(:participant)
      participant.attend!
      participant.save!
      assign(:page_size, 'LETTER')
      assign(:verification_code, participant.verification_code)
      assign(:certificate, ParticipantsHelper::Certificate.new(participant))
      assign(:participant, participant)
      certificate_store = FileStoreService.create_null exists: { "certificate-images/#{ParticipantsHelper::DEFAULT_BACKGROUND_IMAGE_V2}" => false}
      assign(:certificate_store, certificate_store)

      expect do
        render template: 'participants/certificate', format: :pdf
      end.to raise_error(ActionView::Template::Error, /#{ParticipantsHelper::DEFAULT_BACKGROUND_IMAGE_V2}/)
    end
    it '2nd trainer wo signature' do
      participant = FactoryBot.create(:participant)
      participant.event.trainer2 = FactoryBot.create(:trainer, name: 'pepe', signature_image: '')
      participant.event.save!
      participant.attend!
      participant.save!
      assign(:page_size, 'LETTER')
      assign(:verification_code, participant.verification_code)
      assign(:certificate, ParticipantsHelper::Certificate.new(participant))
      assign(:participant, participant)
      assign(:certificate_store, FileStoreService.create_null)

      expect do
        render template: 'participants/certificate', format: :pdf
      end.not_to raise_error
    end
  end
end
