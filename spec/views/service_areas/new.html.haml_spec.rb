require 'rails_helper'

RSpec.describe 'service_areas/new', type: :view do
  before(:each) do
    assign(:service_area, ServiceArea.new(
      name: 'MyString',
      abstract: 'MyText'
    ))
  end

  it 'renders new service_area form' do
    render

    assert_select 'form[action=?][method=?]', service_areas_path, 'post' do
      assert_select 'input[name=?]', 'service_area[name]'
      assert_select 'input[name=?]', 'service_area[abstract]'
    end
  end
end
