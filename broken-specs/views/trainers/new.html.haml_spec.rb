require 'spec_helper'

describe "trainers/new" do
  before(:each) do
    assign(:trainer, stub_model(Trainer,
      :name => "MyString"
    ).as_new_record)
  end

  it "renders new trainer form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => trainers_path, :method => "post" do
      assert_select "input#trainer_name", :name => "trainer[name]"
    end
  end
end
