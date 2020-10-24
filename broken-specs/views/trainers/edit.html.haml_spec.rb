require 'spec_helper'

describe "trainers/edit" do
  before(:each) do
    @trainer = assign(:trainer, stub_model(Trainer,
      :name => "MyString"
    ))
  end

  it "renders the edit trainer form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => trainers_path(@trainer), :method => "post" do
      assert_select "input#trainer_name", :name => "trainer[name]"
    end
  end
end
