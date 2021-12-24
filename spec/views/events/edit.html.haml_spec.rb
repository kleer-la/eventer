require 'rails_helper'

describe "events/edit" do  
  it "renders the edit event form" do
    pending "rendering partial _form"
    event_types= [FactoryBot.create(:event_type,
      :name => "ET Name",
      :description => "ET Descripcion",
      :recipients => "ET Recipients",
      :program => "ET Program"
      )]
    @event = FactoryBot.create(:event,
      :event_type => event_types[0],
      :place => "EvPlace",
      :date => "2025-01-01",
      :capacity => 12358,
      :city => "Ev City"
    )
    # assign(:event, @event)
    @trainers = [FactoryBot.build(:trainer)]
    @categories = [FactoryBot.build(:category)]
    @timezones = ActiveSupport::TimeZone.all
    @currencies = Money::Currency.table
    @event_type_cancellation_policy = @event.event_type.cancellation_policy

    render

    expect(rendered).to match(/ET Name/)
    expect(rendered).to match(/ET Descripcion/)
    expect(rendered).to match(/ET Recipients/)
    expect(rendered).to match(/ET Program/)
  end
end
