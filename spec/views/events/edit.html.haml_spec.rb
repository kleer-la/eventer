require 'rails_helper'

describe "events/edit" do
  before(:each) do
    @countries = [FactoryBot.build(:country)]
    @trainers = [FactoryBot.build(:trainer)]
    @timezones = TimeZone.all
    @currencies = Money::Currency.table

    @event_types= [FactoryBot.create(:event_type,
        :name => "ET Name",
        :description => "ET Descripcion",
        :recipients => "ET Recipients",
        :program => "ET Program"
      )]
    @event = assign(:event, FactoryBot.create(:event,
        :event_type => @event_types[0],
        :place => "EvPlace",
        :date => "2025-01-01",
        :capacity => 12358,
        :city => "Ev City",
        :trainer => @trainers[0]
      ))
    end
  
  it "renders the edit event type form" do
    pending "Not working. Fixed in Rails 4? https://github.com/rails/rails/issues/4401"
    render

    expect(rendered).to match(/ET Name/)
    expect(rendered).to match(/ET Descripcion/)
    expect(rendered).to match(/ET Recipients/)
    expect(rendered).to match(/ET Program/)
  end
end
