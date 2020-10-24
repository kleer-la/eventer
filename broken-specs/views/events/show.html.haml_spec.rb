require 'spec_helper'

describe "events/show" do
  before(:each) do
    @event = assign(:event, stub_model(Event,
      :event_type => FactoryGirl.build(:event_type),
      :place => "Place",
      :date => "2015-01-01",
      :capacity => 20,
      :city => "City",
      :country => FactoryGirl.build(:country),
      :trainer => FactoryGirl.build(:trainer),
      :visibility_type => "Type",
      :list_price => "9.99",
      :list_price_plus_tax => false,
      :list_price_2_pax_discount => 15,
      :list_price_3plus_pax_discount => 25,
      :eb_price => "19.99",
      :draft => true,
      :cancelled => false,
      :is_webinar => false
    ))
  end

  it "renders attributes in <p>" do
    render
  end
end
