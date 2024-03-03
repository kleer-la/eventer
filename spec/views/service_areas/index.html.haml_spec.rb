require 'rails_helper'

RSpec.describe 'service_areas/index', type: :view do
  before(:each) do
    assign(:service_areas, [
      ServiceArea.create!(
        name: 'Name',
        abstract: 'MyText'
      ),
      ServiceArea.create!(
        name: 'Name',
        abstract: 'MyText'
      )
    ])
  end

  it 'renders a list of service_areas' do
    render
    cell_selector = 'tr>td>div>div'
    assert_select 'tr>td', text: Regexp.new('Name'.to_s), count: 2
    assert_select 'tr>td', text: Regexp.new('MyText'.to_s), count: 2
  end
end
