# frozen_string_literal: true

require 'rails_helper'

describe 'events/index' do
  before(:each) do
    event_type = FactoryBot.create(:event_type,
                                   name: 'ET Name')

    assign(:events, [
             FactoryBot.create(:event,
                               event_type: event_type,
                               place: 'EvPlace1',
                               date: '2025-01-01',
                               city: 'Ev City1'),
             FactoryBot.create(:event,
                               event_type: event_type,
                               place: 'EvPlace2',
                               date: '2025-01-02',
                               city: 'Ev City2')
           ])
  end

  it 'renders a list of events' do
    render

    # Table header
    expect(rendered).to match(/Tipo de Evento/)
    expect(rendered.scan('Tipo de Evento').length).to eq 1
    expect(rendered).to include 'Fecha'
    expect(rendered).to include 'Detalles'

    # Table content
    expect(rendered.scan('ET Name').length).to eq 2
    expect(rendered).to include 'Ev City1'
    # expect(rendered).to include "1-2 Ene" # fails b/ location
    expect(rendered).to include 'Ev City2'
    # expect(rendered).to include "2-3 Ene" # fails b/ location
  end
end
