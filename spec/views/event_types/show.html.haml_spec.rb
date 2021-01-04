require 'rails_helper'

describe "event_types/show" do
  before(:each) do
    @event_type = assign(:event_type, 
      FactoryBot.create(:event_type,
      :name => "ET Name",
      :description => "ET Descripcion",
      :recipients => "ET Recipients",
      :program => "ET Program"
    ))
  end

  it "show attributes " do
    render
    expect(rendered).to match(/ET Name/)
    expect(rendered).to match(/ET Descripcion/)
    expect(rendered).to match(/ET Recipients/)
    expect(rendered).to match(/ET Program/)
  end
end
