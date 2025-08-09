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

  describe 'ImageReference behavior' do
    let(:image_url) { 'https://kleer-images.s3.sa-east-1.amazonaws.com/question-group-banner.png' }

    describe '#image_references' do
      let(:question_group) do
        create(:question_group, description: "Group banner: #{image_url}")
      end

      it 'finds embedded references in description text field' do
        references = question_group.image_references(image_url)
        expect(references).to include(
          hash_including(
            field: :description,
            type: 'embedded'
          )
        )
      end

      it 'returns empty array when URL not found' do
        references = question_group.image_references('https://not-found.com/missing.png')
        expect(references).to be_empty
      end
    end
  end
end
