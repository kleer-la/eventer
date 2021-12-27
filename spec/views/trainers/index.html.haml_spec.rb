# frozen_string_literal: true

require 'rails_helper'

describe 'trainers/index' do
  before(:each) do
    assign(:trainers, [
             FactoryBot.create(:trainer, name: 'T Name 1'),
             FactoryBot.create(:trainer, name: 'T Name 2')
           ])
  end

  it 'renders a list of trainers' do
    render

    expect(rendered).to match(/T Name 1/)
    expect(rendered).to match(/T Name 2/)
  end
end
