require 'spec_helper'

describe Country do
  it "shown as AR - Argentina" do
    c = FactoryGirl.build(:country)
    expect(c.to_s).to eq "AR - Argentina"
  end
end
