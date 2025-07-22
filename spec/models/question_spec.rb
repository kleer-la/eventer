require 'rails_helper'

RSpec.describe Question, type: :model do
  describe 'creation' do
    let(:assessment) { Assessment.create(title: 'Skills Assessment', description: 'Evaluate skills') }

    it 'belongs to an assessment as a standalone question' do
      question = assessment.questions.create(name: 'How confident are you?')
      expect(question.persisted?).to be true
      expect(question.assessment).to eq assessment
      expect(question.question_group).to be_nil
      expect(question.name).to eq 'How confident are you?'
    end

    it 'belongs to a question group within an assessment' do
      group = assessment.question_groups.create(name: 'Domain')
      question = group.questions.create(name: 'Domain: Technical mastery')
      puts question.errors.full_messages unless question.persisted? # Debug output
      expect(question.persisted?).to be true
      expect(question.assessment).to eq assessment
      expect(question.question_group).to eq group
      expect(question.name).to eq 'Domain: Technical mastery'
    end
  end

  describe 'question types' do
    let(:assessment) { create(:assessment) }

    it 'defaults to linear_scale type' do
      question = create(:question, assessment: assessment)
      expect(question.question_type).to eq 'linear_scale'
      expect(question.linear_scale?).to be true
    end

    it 'can be created with radio_button type' do
      question = create(:question, :radio_button, assessment: assessment)
      expect(question.question_type).to eq 'radio_button'
      expect(question.radio_button?).to be true
      expect(question.linear_scale?).to be false
    end

    it 'can be created with short_text type' do
      question = create(:question, :short_text, assessment: assessment)
      expect(question.question_type).to eq 'short_text'
      expect(question.short_text?).to be true
      expect(question.linear_scale?).to be false
    end

    it 'can be created with long_text type' do
      question = create(:question, :long_text, assessment: assessment)
      expect(question.question_type).to eq 'long_text'
      expect(question.long_text?).to be true
      expect(question.linear_scale?).to be false
    end

    it 'provides enum methods for all question types' do
      question = create(:question, assessment: assessment)
      
      expect(Question.question_types).to include(
        'linear_scale' => 'linear_scale',
        'radio_button' => 'radio_button', 
        'short_text' => 'short_text',
        'long_text' => 'long_text'
      )
    end

    it 'can change question type' do
      question = create(:question, assessment: assessment)
      expect(question.linear_scale?).to be true
      
      question.update!(question_type: 'radio_button')
      expect(question.radio_button?).to be true
      expect(question.linear_scale?).to be false
    end
  end
end
