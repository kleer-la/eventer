# frozen_string_literal: true

require 'rails_helper'

describe 'event_types/new' do
  before(:each) do
    @trainers = [FactoryBot.build(:trainer)]
    @categories = [FactoryBot.build(:category)]
    assign(:event_type,
           EventType.new)
    @bkgd_imgs =
      @image_list = ['']
  end

  it 'renders new event_type form' do
    render

    expect(rendered).to match(/#{@trainers[0].name}/)
    expect(rendered).to match(/#{@categories[0].name}/)
    expect(rendered).to match(/Tipo de Evento \(\*\)/)
  end
end
