require 'rails_helper'

describe "events/new" do
  before(:each) do
    # @countries = [FactoryBot.create(:country)]
    # @trainers = [FactoryBot.create(:trainer)]
    @timezones = TimeZone.all
    @currencies = Money::Currency.table

    @event_types= [FactoryBot.create(:event_type,
        :name => "ET Name",
      )]

    assign(:event, 
      Event.new
    )
  end

  it "renders new event form" do
    render

    expect(rendered).to match(/#{@timezones[0].name}/)
    expect(rendered).to match(/ET Name/)
    expect(rendered).to match(/USD - United States Dollar/)
    expect(rendered.scan('value="USD"')).to contain_exactly 'value="USD"', 'value="USD"'
    # expect(rendered).to match(/#{@trainers[0].name}/)    # Ajax?
    # expect(rendered).to match(/Argentina}/)              # Ajax?
  end
end
