require 'rails_helper'

RSpec.describe 'services/new', type: :view do
  before(:each) do
    assign(:service, 
      FactoryBot.build(
        :service,
        name: 'MyString',
        card_description: 'MyText',
        subtitle: 'MyString'
      ))
  end

  it 'renders new service form' do
    render

    assert_select 'form[action=?][method=?]', services_path, 'post' do
      assert_select 'input[name=?]', 'service[name]'
      assert_select 'textarea[name=?]', 'service[card_description]'
      assert_select 'input[name=?]', 'service[subtitle]'
      assert_select 'select[name=?]', 'service[service_area_id]'
    end
  end
end
