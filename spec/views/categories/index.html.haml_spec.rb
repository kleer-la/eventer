# frozen_string_literal: true

require 'rails_helper'

describe 'categories/index' do
  before(:each) do
    assign(:categories, [
             FactoryBot.create(:category, name: 'Name 1', codename: 'code1', description: 'Text 1'),
             FactoryBot.create(:category, name: 'Name 2', codename: 'code2', description: 'Text 2')
           ])
  end

  it 'renders a list of categories' do
    render

    expect(rendered).to match(/Name 1/)
    expect(rendered).to match(/Name 2/)
  end
end
