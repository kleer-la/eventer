# frozen_string_literal: true

require 'rails_helper'

describe 'trainers/show' do
  before(:each) do
    @trainer = assign(:trainer, FactoryBot.create(:trainer, name: 'T Name'))
  end

  it 'renders attributes in <p>' do
    render
    expect(rendered).to match(/T Name/)
  end
end
