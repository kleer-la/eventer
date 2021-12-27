# frozen_string_literal: true

require 'rails_helper'

describe 'trainers/edit' do
  before(:each) do
    @trainer = assign(:trainer,
                      FactoryBot.create(:trainer, name: 'T Name'))
  end

  it 'renders the edit trainer form' do
    render

    expect(rendered).to match(/T Name/)
  end
end
