# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventTypeParticipantsService do
  let(:event_type) { create(:event_type, name: 'Test Course') }
  let(:event1) { create(:event, event_type: event_type, date: Date.new(2024, 1, 15)) }
  let(:event2) { create(:event, event_type: event_type, date: Date.new(2024, 2, 20)) }

  let!(:participant1) { create(:participant, event: event1, fname: 'John', lname: 'Doe', status: 'C') }
  let!(:participant2) { create(:participant, event: event1, fname: 'Jane', lname: 'Smith', status: 'A') }
  let!(:participant3) { create(:participant, event: event2, fname: 'Bob', lname: 'Johnson', status: 'K') }

  describe '.participants' do
    context 'when successful' do
      it 'returns all participants across all events for the event type' do
        result = described_class.participants(event_type)

        expect(result).to be_success
        expect(result.data[:participants]).to contain_exactly(participant1, participant2, participant3)
        expect(result.data[:event_type]).to eq(event_type)
        expect(result.data[:total_count]).to eq(3)
      end

      it 'includes associated event data' do
        result = described_class.participants(event_type)

        participants = result.data[:participants]
        expect(participants.first.event).to be_present
      end

      it 'returns empty array when event type has no events' do
        empty_event_type = create(:event_type, name: 'Empty Course')
        result = described_class.participants(empty_event_type)

        expect(result).to be_success
        expect(result.data[:participants]).to be_empty
        expect(result.data[:total_count]).to eq(0)
      end

      it 'returns empty array when events have no participants' do
        empty_event = create(:event, event_type: event_type)
        # Clear existing participants for this test
        Participant.delete_all

        result = described_class.participants(event_type)

        expect(result).to be_success
        expect(result.data[:participants]).to be_empty
        expect(result.data[:total_count]).to eq(0)
      end
    end

    context 'when an error occurs' do
      before do
        allow(event_type).to receive(:events).and_raise(StandardError, 'Database error')
      end

      it 'returns failure result' do
        result = described_class.participants(event_type)

        expect(result).to be_failure
        expect(result.message).to include('Error loading participants')
        expect(result.message).to include('Database error')
      end
    end
  end

  describe '.generate_csv' do
    context 'when successful' do
      it 'generates CSV data for all participants' do
        result = described_class.generate_csv(event_type)

        expect(result).to be_success
        expect(result.data[:csv_data]).to be_present
        expect(result.data[:csv_data]).to include('fname,lname,email,human_status')
        expect(result.data[:csv_data]).to include('John,Doe')
        expect(result.data[:csv_data]).to include('Jane,Smith')
        expect(result.data[:csv_data]).to include('Bob,Johnson')
      end

      it 'generates filename with event type name and current date' do
        allow(Date).to receive(:current).and_return(Date.new(2024, 7, 25))
        result = described_class.generate_csv(event_type)

        expect(result).to be_success
        expect(result.data[:filename]).to eq('participants-test-course-2024-07-25.csv')
      end

      it 'includes participants count' do
        result = described_class.generate_csv(event_type)

        expect(result).to be_success
        expect(result.data[:participants_count]).to eq(3)
      end

      it 'handles event type with no participants' do
        empty_event_type = create(:event_type, name: 'Empty Course')
        result = described_class.generate_csv(empty_event_type)

        expect(result).to be_success
        expect(result.data[:csv_data]).to include('fname,lname,email,human_status')
        expect(result.data[:participants_count]).to eq(0)
      end

      it 'parameterizes event type name for filename' do
        special_event_type = create(:event_type, name: 'Scrum Master & Product Owner!')
        result = described_class.generate_csv(special_event_type)

        expect(result).to be_success
        expect(result.data[:filename]).to include('scrum-master-product-owner')
      end
    end

    context 'when CSV generation fails' do
      before do
        allow(Participant).to receive(:to_csv).and_raise(StandardError, 'CSV generation error')
      end

      it 'returns failure result' do
        result = described_class.generate_csv(event_type)

        expect(result).to be_failure
        expect(result.message).to include('Error generating CSV')
        expect(result.message).to include('CSV generation error')
      end
    end

    context 'when database error occurs' do
      before do
        allow(event_type).to receive(:events).and_raise(StandardError, 'Database connection lost')
      end

      it 'returns failure result' do
        result = described_class.generate_csv(event_type)

        expect(result).to be_failure
        expect(result.message).to include('Error generating CSV')
        expect(result.message).to include('Database connection lost')
      end
    end
  end

  describe 'Result class' do
    it 'has success? and failure? methods' do
      success_result = EventTypeParticipantsService::Result.new(success: true, data: { test: 'data' })
      failure_result = EventTypeParticipantsService::Result.new(success: false, message: 'Error')

      expect(success_result).to be_success
      expect(success_result).not_to be_failure
      expect(success_result.data[:test]).to eq('data')

      expect(failure_result).to be_failure
      expect(failure_result).not_to be_success
      expect(failure_result.message).to eq('Error')
    end
  end
end
