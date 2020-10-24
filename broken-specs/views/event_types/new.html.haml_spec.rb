require 'spec_helper'

describe "event_types/new" do
  before(:each) do
    @trainers = Trainer.all
    @categories = Category.all
    assign(:event_type, stub_model(EventType,
      :name => "MyString",
      :description => "MyText",
      :recipients => "MyText",
      :program => "MyText"
    ).as_new_record)
  end

  it "renders new event_type form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => event_types_path, :method => "post" do
      assert_select "input#event_type_name", :name => "event_type[name]"
      assert_select "textarea#event_type_description", :name => "event_type[description]"
      assert_select "textarea#event_type_recipients", :name => "event_type[recipients]"
      assert_select "textarea#event_type_program", :name => "event_type[program]"
    end
  end
end
