# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'services/edit', type: :view do
  let(:service) {
    FactoryBot.create(
      :service,
      name: 'MyString',
      card_description: 'MyText',
      subtitle: 'MyString'
    )
  }

  before(:each) do
    assign(:service, service)
  end

  it 'renders the edit service form' do
    render

    assert_select 'form[action=?][method=?]', service_path(service), 'post' do
      assert_select 'input[name=?]', 'service[name]'
      assert_select 'textarea[name=?]', 'service[card_description]'
      assert_select 'input[name=?]', 'service[subtitle]'
      assert_select 'select[name=?]', 'service[service_area_id]'
    end
  end
end
