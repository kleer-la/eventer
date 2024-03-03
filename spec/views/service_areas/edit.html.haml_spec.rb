require 'rails_helper'

RSpec.describe 'service_areas/edit', type: :view do
  let(:service_area) {
    ServiceArea.create!(
      name: 'MyString',
      abstract: 'MyText'
    )
  }

  before(:each) do
    assign(:service_area, service_area)
  end

  it 'renders the edit service_area form' do
    render

    assert_select 'form[action=?][method=?]', service_area_path(service_area), 'post' do

      assert_select 'input[name=?]', 'service_area[name]'

      assert_select 'input[name=?]', 'service_area[abstract]'
    end
  end
end
