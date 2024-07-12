# frozen_string_literal: true

require 'rails_helper'

describe 'home/index.html.haml' do
  before(:each) do
    event_type = FactoryBot.create(:event_type,
                                   name: 'ET Name')

    assign(:events, [
             FactoryBot.create(:event,
                               event_type:,
                               place: 'EvPlace1',
                               date: '2025-01-01',
                               city: 'Ev City1'),
             FactoryBot.create(:event,
                               event_type:,
                               place: 'EvPlace2',
                               date: '2025-01-02',
                               city: 'Ev City2')
           ])
  end

  it 'renders a list of events' do
    render
    # Table header
    expect(rendered).to match(/Nombre/)
    expect(rendered.scan('Fecha').length).to eq 1
    expect(rendered.scan('Nombre').length).to eq 1
    expect(rendered.scan('Ciudad').length).to eq 1
    expect(rendered.scan('País').length).to eq 1

    # Table content
    expect(rendered.scan('ET Name').length).to eq 2
    expect(rendered.scan('Ev City1').length).to eq 1
    expect(rendered.scan('2025-01-01').length).to eq 1
    expect(rendered.scan('Ev City2').length).to eq 1
    expect(rendered.scan('2025-01-02').length).to eq 1
  end
end
