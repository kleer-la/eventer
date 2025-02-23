require 'rails_helper'

RSpec.describe Answer, type: :model do
  describe 'creation' do
    let(:assessment) { Assessment.create(title: 'Skills Assessment', description: 'Evaluate skills') }
    let(:question) { assessment.questions.create(text: 'How confident are you?') }

    it 'belongs to a question and has text and position' do
      answer = question.answers.create(text: 'Low', position: 1)
      expect(answer.persisted?).to be true
      expect(answer.question).to eq question
      expect(answer.text).to eq 'Low'
      expect(answer.position).to eq 1
    end
  end
end
