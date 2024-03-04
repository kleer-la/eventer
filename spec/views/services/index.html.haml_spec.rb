# frozen_string_literal: true

# frozen_string_literal: truerequire 'rails_helper'

RSpec.describe 'services/index', type: :view do
  before(:each) do
    assign(:services, [
      FactoryBot.create(
        :service,
        name: 'Name 1',
        card_description: 'MyText',
        subtitle: 'Subtitle'
      ),
      FactoryBot.create(
        :service,
        name: 'Name 2',
        card_description: 'MyText',
        subtitle: 'Subtitle'
      )])
  end
#content-wrapper > div > table > tbody > tr > td:nth-child(1)
  it 'renders a list of services' do
    render
    cell_selector = 'table > tbody > tr > td'
    assert_select cell_selector, text: Regexp.new('Name 1'.to_s), count: 1
    assert_select cell_selector, text: Regexp.new('MyText'.to_s), count: 2
    assert_select cell_selector, text: Regexp.new('Subtitle'.to_s), count: 2
  end
end
