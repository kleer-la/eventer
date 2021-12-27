# frozen_string_literal: true

require 'rails_helper'

describe 'events/show' do
  before(:each) do
    event_type = FactoryBot.create(:event_type,
                                   name: 'ET Name',
                                   description: 'ET Descripcion',
                                   recipients: 'ET Recipients',
                                   program: 'ET Program')
    @event = assign(:event, FactoryBot.create(:event,
                                              event_type: event_type,
                                              place: 'EvPlace',
                                              date: '2025-01-01',
                                              capacity: 12_358,
                                              city: 'Ev City',
                                              trainer: FactoryBot.build(:trainer, name: 'Ev Trainer')))
  end

  it 'show attributes' do
    render
    expect(rendered).to match(/ET Name/)
    expect(rendered).to match(/ET Descripcion/)
    expect(rendered).to match(/ET Recipients/)

    expect(rendered).to match(/2025-01-01/)
    expect(rendered).to match(/Ev City/)
    expect(rendered).to match(/12358/)
  end
end
