require 'spec_helper'

describe "trainers/show" do
  before(:each) do
    @trainer = assign(:trainer, stub_model(Trainer,
      :name => "Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
  end
end
