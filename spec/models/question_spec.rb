require 'rails_helper'

RSpec.describe Question, type: :model do
  describe 'creation' do
    let(:assessment) { Assessment.create(title: 'Skills Assessment', description: 'Evaluate skills') }

    it 'belongs to an assessment as a standalone question' do
      question = assessment.questions.create(text: 'How confident are you?')
      expect(question.persisted?).to be true
      expect(question.assessment).to eq assessment
      expect(question.question_group).to be_nil
      expect(question.text).to eq 'How confident are you?'
    end

    it 'belongs to a question group within an assessment' do
      group = assessment.question_groups.create(name: 'Domain')
      question = group.questions.create(text: 'Domain: Technical mastery')
      puts question.errors.full_messages unless question.persisted? # Debug output
      expect(question.persisted?).to be true
      expect(question.assessment).to eq assessment
      expect(question.question_group).to eq group
      expect(question.text).to eq 'Domain: Technical mastery'
    end
  end
end
