require 'spec_helper'

describe CrmPushTransaction do
    pending "delete - unused  #{__FILE__}"
=begin
    it "should notify when finished" do
        event = FactoryGirl.create(:event)
        user = FactoryGirl.create(:user)
        crm_push = CrmPushTransaction.create( :event => event, :user => user )
        notificator = double(EventMailer)

        allow(notificator).to receive(:alert_event_crm_push_finished)
        crm_push.start! (notificator)
  end
=end
end
