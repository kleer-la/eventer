require 'rails_helper'

RSpec.describe Answer, type: :model do
  describe 'creation' do
    let(:assessment) { Assessment.create(title: 'Skills Assessment', description: 'Evaluate skills') }
    let(:question) { assessment.questions.create(name: 'How confident are you?') }

    it 'belongs to a question and has text and position' do
      answer = question.answers.create(text: 'Low', position: 1)
      expect(answer.persisted?).to be true
      expect(answer.question).to eq question
      expect(answer.text).to eq 'Low'
      expect(answer.position).to eq 1
    end
  end

  describe 'ImageReference behavior' do
    let(:image_url) { 'https://kleer-images.s3.sa-east-1.amazonaws.com/answer-option.png' }

    describe '#image_references' do
      let(:answer) do
        create(:answer, text: "See option diagram: #{image_url}")
      end

      it 'finds embedded references in text field' do
        references = answer.image_references(image_url)
        expect(references).to include(
          hash_including(
            field: :text,
            type: 'embedded'
          )
        )
      end

      it 'returns empty array when URL not found' do
        references = answer.image_references('https://not-found.com/missing.png')
        expect(references).to be_empty
      end
    end
  end
end
