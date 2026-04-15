# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Booking, type: :model do
  describe 'validations' do
    it 'is valid with all required attributes' do
      booking = FactoryBot.build(:booking)
      expect(booking).to be_valid
    end

    it 'requires visitor_name' do
      booking = FactoryBot.build(:booking, visitor_name: nil)
      expect(booking).not_to be_valid
    end

    it 'requires visitor_email' do
      booking = FactoryBot.build(:booking, visitor_email: nil)
      expect(booking).not_to be_valid
    end

    it 'requires a valid email format' do
      booking = FactoryBot.build(:booking, visitor_email: 'not-an-email')
      expect(booking).not_to be_valid
    end

    it 'requires starts_at' do
      booking = FactoryBot.build(:booking, starts_at: nil)
      expect(booking).not_to be_valid
    end

    it 'requires ends_at' do
      booking = FactoryBot.build(:booking, ends_at: nil)
      expect(booking).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a trainer' do
      booking = FactoryBot.create(:booking)
      expect(booking.trainer).to be_a(Trainer)
    end

    it 'optionally belongs to a service area' do
      booking = FactoryBot.build(:booking, service_area: nil)
      expect(booking).to be_valid
    end
  end

  describe 'status enum' do
    it 'defaults to confirmed' do
      booking = FactoryBot.create(:booking)
      expect(booking.status).to eq('confirmed')
    end

    it 'can be set to cancelled' do
      booking = FactoryBot.create(:booking, status: :cancelled)
      expect(booking).to be_cancelled
    end

    it 'can be set to pending' do
      booking = FactoryBot.create(:booking, status: :pending)
      expect(booking).to be_pending
    end
  end

  describe 'qualifying_answers' do
    it 'stores and retrieves JSON data' do
      answers = { 'question1' => 'answer1', 'question2' => 'answer2' }
      booking = FactoryBot.create(:booking, qualifying_answers: answers)
      booking.reload
      expect(booking.qualifying_answers).to eq(answers)
    end
  end
end
