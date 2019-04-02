require "spec_helper"

describe PayuCoConfirmationService do


  before(:each) do
    @event = FactoryGirl.build(:event)
    @event.id=11
    @participant = FactoryGirl.build(:participant)
    @participant.id=110
    allow(Event).to receive(:find).with(@event.id).and_return(@event)
    allow(Participant).to receive(:find).with(@participant.id).and_return(@participant)
  end


  it 'should be a valid sign' do
    confirmation = PayuCoConfirmationService.new({state_pol: "6",
                                                  reference_sale: "TestPayU04",
                                                  value: "150.00",
                                                  sign: "30ce6597d4a4d58469ad4dc876e0f12d",
                                                  extra2: @event.id,
                                                  extra1: @participant.id})

    confirmation.is_valid_signature?.should == true
  end
end