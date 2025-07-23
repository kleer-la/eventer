# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Response, type: :model do
  let(:assessment) { create(:assessment) }
  let(:contact) { create(:contact, assessment: assessment) }

  describe 'associations' do
    it 'belongs to contact' do
      response = Response.reflect_on_association(:contact)
      expect(response.macro).to eq(:belongs_to)
    end

    it 'belongs to question' do
      response = Response.reflect_on_association(:question)
      expect(response.macro).to eq(:belongs_to)
    end

    it 'optionally belongs to answer' do
      response = Response.reflect_on_association(:answer)
      expect(response.macro).to eq(:belongs_to)
      expect(response.options[:optional]).to be true
    end
  end

  describe 'creation with existing structure' do
    let(:question) { create(:question, assessment: assessment) }
    let(:answer) { create(:answer, question: question) }

    it 'belongs to a contact, question, and answer' do
      response = contact.responses.create(question:, answer:)
      expect(response.persisted?).to be true
      expect(response.contact).to eq contact
      expect(response.question).to eq question
      expect(response.answer).to eq answer
    end
  end

  describe 'validations for linear_scale questions' do
    let(:question) { create(:question, :linear_scale, assessment: assessment) }
    let(:answer) { create(:answer, question: question) }

    it 'requires an answer for linear_scale questions' do
      response = Response.new(contact: contact, question: question)
      expect(response).not_to be_valid
      expect(response.errors[:answer]).to include(match(/can't be blank|no puede estar en blanco/))
    end

    it 'does not allow text_response for linear_scale questions' do
      response = Response.new(contact: contact, question: question, answer: answer, text_response: 'some text')
      expect(response).not_to be_valid
      expect(response.errors[:text_response]).to include(match(/must be blank|debe estar en blanco/))
    end

    it 'is valid with answer and no text_response' do
      response = Response.new(contact: contact, question: question, answer: answer)
      expect(response).to be_valid
    end
  end

  describe 'validations for radio_button questions' do
    let(:question) { create(:question, :radio_button, assessment: assessment) }
    let(:answer) { create(:answer, question: question) }

    it 'requires an answer for radio_button questions' do
      response = Response.new(contact: contact, question: question)
      expect(response).not_to be_valid
      expect(response.errors[:answer]).to include(match(/can't be blank|no puede estar en blanco/))
    end

    it 'does not allow text_response for radio_button questions' do
      response = Response.new(contact: contact, question: question, answer: answer, text_response: 'some text')
      expect(response).not_to be_valid
      expect(response.errors[:text_response]).to include(match(/must be blank|debe estar en blanco/))
    end
  end

  describe 'validations for short_text questions' do
    let(:question) { create(:question, :short_text, assessment: assessment) }

    it 'requires text_response for short_text questions' do
      response = Response.new(contact: contact, question: question)
      expect(response).not_to be_valid
      expect(response.errors[:text_response]).to include(match(/can't be blank|no puede estar en blanco/))
    end

    it 'does not allow answer for short_text questions' do
      answer = create(:answer, question: create(:question, :linear_scale, assessment: assessment))
      response = Response.new(contact: contact, question: question, answer: answer, text_response: 'valid text')
      expect(response).not_to be_valid
      expect(response.errors[:answer]).to include(match(/must be blank|debe estar en blanco/))
    end

    it 'is valid with text_response and no answer' do
      response = Response.new(contact: contact, question: question, text_response: 'This is my answer')
      expect(response).to be_valid
    end
  end

  describe 'validations for long_text questions' do
    let(:question) { create(:question, :long_text, assessment: assessment) }

    it 'requires text_response for long_text questions' do
      response = Response.new(contact: contact, question: question)
      expect(response).not_to be_valid
      expect(response.errors[:text_response]).to include(match(/can't be blank|no puede estar en blanco/))
    end

    it 'does not allow answer for long_text questions' do
      answer = create(:answer, question: create(:question, :linear_scale, assessment: assessment))
      response = Response.new(contact: contact, question: question, answer: answer, text_response: 'valid long text')
      expect(response).not_to be_valid
      expect(response.errors[:answer]).to include(match(/must be blank|debe estar en blanco/))
    end

    it 'is valid with text_response and no answer' do
      response = Response.new(contact: contact, question: question, text_response: 'This is my long detailed answer explaining everything.')
      expect(response).to be_valid
    end
  end
end
