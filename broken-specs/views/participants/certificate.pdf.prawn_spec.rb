# encoding: utf-8
require 'spec_helper'

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

  it "abort when trainer has no signature" do
    participant= FactoryBot.create(:participant)
    participant.attend!
    participant.save!
    trainer= participant.event.trainer
    trainer.signature_image= nil
#    trainer.save!
    assign(:page_size, 'LETTER')
    assign(:verification_code, participant.verification_code)
    assign(:certificate, ParticipantsHelper::Certificate.new(participant) )
    assign(:participant, participant )

    render :template => "participants/certificate", format: :pdf
    texts= PDF::Inspector::Text.analyze(rendered).strings
    expect(texts.join ' ').to include 'Firma del trainer'
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
end
