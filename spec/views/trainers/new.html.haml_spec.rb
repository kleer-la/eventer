# frozen_string_literal: true

require 'rails_helper'

describe 'trainers/new' do
  before(:each) do
    assign(:trainer, Trainer.new)
  end

  it 'renders new trainer form' do
    # I18n.locale=:en

    render

    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Bio EN/)
  end
end
