require 'spec_helper'

describe "trainers/index" do
  before(:each) do
    assign(:trainers, [
      stub_model(Trainer,
        :name => "Name"
      ),
      stub_model(Trainer,
        :name => "Name"
      )
    ])
  end

  it "renders a list of trainers" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
  end
end
