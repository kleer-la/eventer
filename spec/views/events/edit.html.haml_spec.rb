# frozen_string_literal: true

require 'rails_helper'

describe 'events/edit' do
  it 'renders the edit event form' do
    event_types = [FactoryBot.create(:event_type,
                                     name: 'ET Name',
                                     description: 'ET Descripcion',
                                     recipients: 'ET Recipients',
                                     program: 'ET Program')]
    event = FactoryBot.create(:event,
                               event_type: event_types[0],
                               place: 'EvPlace',
                               date: '2025-01-01',
                               capacity: 12_358,
                               city: 'Ev City')
    
    # Assign instance variables needed by the view
    assign(:event, event)
    assign(:event_types, event_types)
    assign(:trainers, [FactoryBot.build(:trainer)])
    assign(:categories, [FactoryBot.build(:category)])
    assign(:timezones, ActiveSupport::TimeZone.all)
    assign(:currencies, Money::Currency.table)
    assign(:event_type_cancellation_policy, event.event_type.cancellation_policy)

    # Mock the controller and routes
    allow(view).to receive(:url_for).and_return('/events/1/edit')
    allow(view).to receive(:events_path).and_return('/events')
    
    render

    # Test that the form renders with the event type name
    expect(rendered).to match(/ET Name/)
    # Test that the form has the expected structure
    expect(rendered).to include('form')
    expect(rendered).to include('event_event_type_id')
    expect(rendered).to include('event_date')
  end
end
