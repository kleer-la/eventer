require 'spec_helper'

describe "events/new" do
  before(:each) do
    @countries = Country.all
    @trainers = Trainer.all
    @timezones = TimeZone.all
    @currencies = Money::Currency.table
    assign(:event, stub_model(Event,
      :name => "MyString",
      :place => "MyString",
      :capacity => 1,
      :city => "MyString",
      :country => FactoryGirl.build(:country),
      :trainer => FactoryGirl.build(:trainer),
      :visibility_type => "",
      :list_price => "9.99",
      :list_price_plus_tax => false,
      :list_price_2_pax_discount => 1,
      :list_price_3plus_pax_discount => 1,
      :eb_price => "9.99",
      :description => "MyText",
      :recipients => "MyText",
      :program => "MyText",
      :draft => false,
      :cancelled => false,
      :mode => "cl"
    ).as_new_record)
  end

  it "renders new event form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => events_path, :method => "post" do
      assert_select "select#event_event_type_id", :name => "event[event_type_id]"
      assert_select "input#event_place", :name => "event[place]"
      assert_select "input#event_capacity", :name => "event[capacity]"
      assert_select "input#event_city", :name => "event[city]"
      assert_select "select#event_country_id", :name => "event[country_id]"
      assert_select "select#event_trainer_id", :name => "event[trainer_id]"
      assert_select "input#event_visibility_type_pu", :name => "event[visibility_type]"
      assert_select "input#event_visibility_type_pr", :name => "event[visibility_type]"
      assert_select "input#event_list_price", :name => "event[list_price]"
      assert_select "input#event_eb_price", :name => "event[eb_price]"
      assert_select "input#event_draft", :name => "event[draft]"
      assert_select "input#event_cancelled", :name => "event[cancelled]"
      assert_select "select#event_mode", :name => "event[mode]"
    end
  end
end
