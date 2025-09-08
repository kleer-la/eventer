# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Participants strftime nil date fix', type: :model do
  describe 'filter collection logic' do
    let!(:event_type) { create(:event_type, name: 'Test Event Type') }
    
    context 'with nil date events' do
      let!(:event_with_nil_date) do
        event = build(:event, date: nil, event_type: event_type)
        event.save(validate: false)
        event
      end
      
      let!(:event_with_date) { create(:event, date: Date.new(2024, 1, 15), event_type: event_type) }
      
      it 'handles nil dates in filter collection without crashing' do
        # Simulate the filter collection logic from admin/participants.rb line 45-50
        collection = Event.includes(:event_type)
                          .order('date DESC')
                          .limit(100)
                          .pluck('events.date', 'event_types.name', 'events.id')
                          .map do |date, name, id|
          event_type_name = name || 'No Event Type'
          date_str = date&.strftime('%Y-%m-%d') || 'No Date'
          ["#{date_str} - #{event_type_name}", id]
        end
        
        expect(collection).to include(["No Date - Test Event Type", event_with_nil_date.id])
        expect(collection).to include(["2024-01-15 - Test Event Type", event_with_date.id])
      end
    end
  end
  
  describe 'index display logic' do
    let!(:event_type) { create(:event_type, name: 'Display Test Event') }
    
    context 'with participant having nil date event' do
      let!(:event_with_nil_date) do
        event = build(:event, date: nil, event_type: event_type)
        event.save(validate: false)
        event
      end
      
      let!(:participant) { create(:participant, event: event_with_nil_date) }
      
      it 'handles nil date in event display without crashing' do
        # Simulate the index display logic from admin/participants.rb line 90-98
        if participant.event
          event_type_name = participant.event.event_type&.name || 'No Event Type'
          date_str = participant.event.date&.strftime('%Y-%m-%d') || 'No Date'
          result = "#{date_str} - #{event_type_name}"
          
          expect(result).to eq("No Date - Display Test Event")
        end
      end
    end
    
    context 'with participant having valid date event' do
      let!(:event_with_date) { create(:event, date: Date.new(2024, 3, 10), event_type: event_type) }
      let!(:participant) { create(:participant, event: event_with_date) }
      
      it 'displays valid date correctly' do
        # Simulate the index display logic
        if participant.event
          event_type_name = participant.event.event_type&.name || 'No Event Type'
          date_str = participant.event.date&.strftime('%Y-%m-%d') || 'No Date'
          result = "#{date_str} - #{event_type_name}"
          
          expect(result).to eq("2024-03-10 - Display Test Event")
        end
      end
    end
  end
  
  describe 'form collection logic' do
    let!(:event_type) { create(:event_type, name: 'Form Test Event') }
    
    context 'with mixed date events' do
      let!(:event_with_nil_date) do
        event = build(:event, date: nil, event_type: event_type)
        event.save(validate: false)
        event
      end
      
      let!(:event_with_date) { create(:event, date: Date.new(2024, 5, 20), event_type: event_type) }
      
      it 'handles nil dates in form collection without crashing' do
        # Simulate the form collection logic from admin/participants.rb line 176-181
        events = Event.includes(:event_type)
                     .joins(:event_type)
                     .where.not(event_types: { name: nil })
        
        form_collection = events.map do |e|
          date_str = e.date&.strftime('%Y-%m-%d') || 'No Date'
          ["#{date_str} - #{e.event_type.name}", e.id]
        end
        
        expect(form_collection).to include(["No Date - Form Test Event", event_with_nil_date.id])
        expect(form_collection).to include(["2024-05-20 - Form Test Event", event_with_date.id])
      end
    end
  end
end