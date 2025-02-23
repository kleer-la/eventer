require 'rails_helper'

RSpec.describe QuestionGroup, type: :model do
  describe 'creation' do
    it 'belongs to an assessment and has a name' do
      assessment = Assessment.create(title: 'Skills Assessment', description: 'Evaluate skills')
      question_group = assessment.question_groups.create(name: 'Domain')
      expect(question_group.persisted?).to be true
      expect(question_group.assessment).to eq assessment
      expect(question_group.name).to eq 'Domain'
    end
  end
end
