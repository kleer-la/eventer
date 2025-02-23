require 'rails_helper'

RSpec.describe Assessment, type: :model do
  describe 'creation' do
    it 'creates an assessment with title and description' do
      assessment = Assessment.create(title: 'Skills Assessment', description: 'Evaluate skills')
      expect(assessment.persisted?).to be true
      expect(assessment.title).to eq 'Skills Assessment'
      expect(assessment.description).to eq 'Evaluate skills'
    end
  end
end
