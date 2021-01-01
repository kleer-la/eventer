require 'rails_helper'

describe Country do
  it "shown as AR - Argentina" do
    c = FactoryBot.build(:country)
    expect(c.to_s).to eq "AR - Argentina"
  end
end
