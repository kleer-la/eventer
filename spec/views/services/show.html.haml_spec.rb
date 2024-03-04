require 'rails_helper'

RSpec.describe 'services/show', type: :view do
  before(:each) do
    assign(:service, 
      FactoryBot.create(
        :service,
        name: 'Name',
        card_description: 'MyText',
        subtitle: 'Subtitle'
    ))
  end

  it 'renders attributes in <p>' do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/Subtitle/)
    expect(rendered).to match(//)
  end
end
