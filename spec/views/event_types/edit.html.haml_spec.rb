require 'rails_helper'

describe "event_types/edit" do
  before(:each) do
    @trainers = [FactoryBot.build(:trainer)]
    @categories = [FactoryBot.build(:category)]

    @event_type = assign(:event_type, 
        FactoryBot.create(:event_type,
        :name => "ET Name",
        :trainers => @trainers,
        :description => "ET Descripcion",
        :recipients => "ET Recipients",
        :program => "ET Program"
      ))
    end
  
  it "renders the edit event type form" do
    render

    expect(rendered).to match(/ET Name/)
    expect(rendered).to match(/ET Descripcion/)
    expect(rendered).to match(/ET Recipients/)
    expect(rendered).to match(/ET Program/)
  end
end
