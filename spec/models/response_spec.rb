require 'rails_helper'

RSpec.describe Response, type: :model do
  describe 'creation' do
    let(:assessment) { Assessment.create(title: 'Skills Assessment', description: 'Evaluate skills') }
    let(:question) { assessment.questions.create(text: 'How confident are you?') }
    let(:answer) { question.answers.create(text: 'Low', position: 1) }
    let(:contact) do
      assessment.contacts.create(
        trigger_type: :assessment_submission,
        email: 'jane@acme.com',
        form_data: { name: 'Jane', company: 'Acme' }
      )
    end

    it 'belongs to a contact, question, and answer' do
      response = contact.responses.create(question:, answer:)
      expect(response.persisted?).to be true
      expect(response.contact).to eq contact
      expect(response.question).to eq question
      expect(response.answer).to eq answer
    end
  end
end
