require 'rails_helper'

RSpec.describe Assessment, type: :model do
  describe 'associations' do
    let(:assessment) { create(:assessment) }

    it 'belongs to resource (optional)' do
      assessment.resource = nil
      expect(assessment).to be_valid
    end

    it 'has many question_groups' do
      expect(assessment).to respond_to(:question_groups)
    end

    it 'has many questions' do
      expect(assessment).to respond_to(:questions)
    end

    it 'has many contacts' do
      expect(assessment).to respond_to(:contacts)
    end

    it 'has many rules' do
      expect(assessment).to respond_to(:rules)
    end
  end

  describe 'validations' do
    it 'validates presence of language' do
      assessment = build(:assessment, language: nil)
      expect(assessment).not_to be_valid
      expect(assessment.errors[:language]).to include("no puede estar en blanco")
    end

    it 'validates language inclusion in allowed values' do
      valid_assessment = build(:assessment, language: 'es')
      expect(valid_assessment).to be_valid

      invalid_assessment = build(:assessment, language: 'fr')
      expect(invalid_assessment).not_to be_valid
      expect(invalid_assessment.errors[:language]).to include("no está incluido en la lista")
    end
  end

  describe 'default values' do
    let(:assessment) { create(:assessment) }

    it 'defaults language to es' do
      expect(assessment.language).to eq('es')
    end

    it 'defaults rule_based to false' do
      expect(assessment.rule_based).to be false
    end
  end

  describe '#responses_for_contact' do
    let(:assessment) { create(:assessment) }
    let(:other_assessment) { create(:assessment) }
    let(:question1) { create(:question, assessment: assessment) }
    let(:question2) { create(:question, assessment: assessment) }
    let(:other_question) { create(:question, assessment: other_assessment) }
    let(:contact) { create(:contact, assessment: assessment) }
    let(:answer1) { create(:answer, question: question1) }
    let(:answer2) { create(:answer, question: question2) }
    let(:other_answer) { create(:answer, question: other_question) }

    let!(:response1) { create(:response, contact: contact, question: question1, answer: answer1) }
    let!(:response2) { create(:response, contact: contact, question: question2, answer: answer2) }
    let!(:other_response) { create(:response, contact: contact, question: other_question, answer: other_answer) }

    it 'returns only responses for questions in this assessment' do
      responses = assessment.responses_for_contact(contact)
      expect(responses).to contain_exactly(response1, response2)
      expect(responses).not_to include(other_response)
    end

    it 'returns empty array when contact has no responses in this assessment' do
      other_contact = create(:contact, assessment: assessment)
      responses = assessment.responses_for_contact(other_contact)
      expect(responses).to be_empty
    end
  end

  describe '#evaluate_rules_for_contact' do
    let(:assessment) { create(:assessment, rule_based: true) }
    let(:question) { create(:question, assessment: assessment, question_type: 'linear_scale') }
    let(:answer1) { create(:answer, question: question, position: 1) }
    let(:answer2) { create(:answer, question: question, position: 2) }
    let(:answer3) { create(:answer, question: question, position: 3) }
    let(:contact) { create(:contact, assessment: assessment) }

    context 'when assessment is not rule_based' do
      let(:assessment) { create(:assessment, rule_based: false) }

      it 'returns empty array' do
        expect(assessment.evaluate_rules_for_contact(contact)).to eq([])
      end
    end

    context 'when assessment is rule_based' do
      let!(:rule1) do
        create(:rule, 
               assessment: assessment, 
               position: 1,
               diagnostic_text: "You are a beginner",
               conditions: { question.id => { "value" => 1 } }.to_json)
      end
      
      let!(:rule2) do
        create(:rule, 
               assessment: assessment, 
               position: 2,
               diagnostic_text: "You are intermediate",
               conditions: { question.id => { "range" => [2, 3] } }.to_json)
      end
      
      let!(:rule3) do
        create(:rule, 
               assessment: assessment, 
               position: 3,
               diagnostic_text: "You answered something",
               conditions: { question.id => nil }.to_json)
      end

      context 'when multiple rules match' do
        before do
          create(:response, contact: contact, question: question, answer: answer2)
        end

        it 'returns diagnostics from all matching rules in position order' do
          diagnostics = assessment.evaluate_rules_for_contact(contact)
          expect(diagnostics).to eq([
            "You are intermediate",      # rule2 matches (value 2 in range [2,3])
            "You answered something"     # rule3 matches (any value)
          ])
        end
      end

      context 'when only some rules match' do
        before do
          create(:response, contact: contact, question: question, answer: answer1)
        end

        it 'returns diagnostics only from matching rules' do
          diagnostics = assessment.evaluate_rules_for_contact(contact)
          expect(diagnostics).to eq([
            "You are a beginner",        # rule1 matches (value 1)
            "You answered something"     # rule3 matches (any value)
          ])
        end
      end

      context 'when no rules match' do
        # No responses created for contact

        it 'returns empty array' do
          diagnostics = assessment.evaluate_rules_for_contact(contact)
          expect(diagnostics).to eq([])
        end
      end

      context 'with complex rule conditions' do
        let(:text_question) { create(:question, assessment: assessment, question_type: 'short_text') }
        let!(:complex_rule) do
          create(:rule,
                 assessment: assessment,
                 position: 4,
                 diagnostic_text: "Complex condition met",
                 conditions: { 
                   question.id => { "range" => [2, 3] },
                   text_question.id => { "text_contains" => "agile" }
                 }.to_json)
        end

        before do
          create(:response, contact: contact, question: question, answer: answer2)
          create(:response, contact: contact, question: text_question, answer: nil, text_response: "I love agile methods")
        end

        it 'evaluates complex multi-question conditions' do
          diagnostics = assessment.evaluate_rules_for_contact(contact)
          expect(diagnostics).to include("Complex condition met")
        end
      end
    end
  end

  describe 'rule ordering' do
    let(:assessment) { create(:assessment, rule_based: true) }
    let!(:rule_position_3) { create(:rule, assessment: assessment, position: 3, diagnostic_text: "Third") }
    let!(:rule_position_1) { create(:rule, assessment: assessment, position: 1, diagnostic_text: "First") }
    let!(:rule_position_2) { create(:rule, assessment: assessment, position: 2, diagnostic_text: "Second") }

    it 'evaluates rules in position order' do
      # Mock all rules to match
      allow_any_instance_of(Rule).to receive(:match?).and_return(true)
      
      contact = create(:contact, assessment: assessment)
      diagnostics = assessment.evaluate_rules_for_contact(contact)
      
      expect(diagnostics).to eq(["First", "Second", "Third"])
    end
  end

  describe 'ImageReference behavior' do
    let(:image_url) { 'https://kleer-images.s3.sa-east-1.amazonaws.com/assessment-diagram.png' }

    describe '#image_references' do
      let(:assessment) do
        create(:assessment, description: "Check this diagram: #{image_url} for details")
      end

      it 'finds embedded references in description text field' do
        references = assessment.image_references(image_url)
        expect(references).to include(
          hash_including(
            field: :description,
            type: 'embedded'
          )
        )
      end

      it 'returns empty array when URL not found' do
        references = assessment.image_references('https://not-found.com/missing.png')
        expect(references).to be_empty
      end
    end
  end
end