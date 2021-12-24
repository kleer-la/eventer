require 'rails_helper'

describe MarketingHelper do
  pending "empty when range is empty" do
    r= Date.parse("2021-01-01")..Date.parse("2021-01-01")
    eventos= MarketingHelper.training(r)
    expect(eventos.count).to eq 0
  end
end
