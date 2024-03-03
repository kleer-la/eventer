require 'rails_helper'

RSpec.describe "service_areas/show", type: :view do
  before(:each) do
    assign(:service_area, ServiceArea.create!(
      name: "Name",
      abstract: "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
  end
end
