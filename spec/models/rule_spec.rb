require 'rails_helper'

RSpec.describe Rule, type: :model do
  let(:assessment) { create(:assessment, rule_based: true) }
  let(:question) { create(:question, assessment: assessment, question_type: 'linear_scale') }
  let(:answer1) { create(:answer, question: question, position: 1) }
  let(:answer2) { create(:answer, question: question, position: 2) }
  let(:answer3) { create(:answer, question: question, position: 3) }
  let(:contact) { create(:contact, assessment: assessment) }

  describe 'associations' do
    it 'belongs to assessment' do
      rule = build(:rule, assessment: assessment)
      expect(rule.assessment).to eq(assessment)
    end
  end

  describe 'validations' do
    it 'validates presence of position' do
      rule = build(:rule, assessment: assessment, position: nil)
      expect(rule).not_to be_valid
      expect(rule.errors[:position]).to include("no puede estar en blanco")
    end

    it 'validates presence of diagnostic_text' do
      rule = build(:rule, assessment: assessment, diagnostic_text: nil)
      expect(rule).not_to be_valid
      expect(rule.errors[:diagnostic_text]).to include("no puede estar en blanco")
    end

    it 'validates presence of conditions' do
      rule = build(:rule, assessment: assessment, conditions: nil)
      expect(rule).not_to be_valid
      expect(rule.errors[:conditions]).to include("no puede estar en blanco")
    end

    it 'validates uniqueness of position scoped to assessment' do
      create(:rule, assessment: assessment, position: 1)
      duplicate_rule = build(:rule, assessment: assessment, position: 1)
      expect(duplicate_rule).not_to be_valid
      expect(duplicate_rule.errors[:position]).to include("ya está en uso")
    end

    it 'allows same position for different assessments' do
      other_assessment = create(:assessment)
      create(:rule, assessment: assessment, position: 1)
      rule_in_other_assessment = build(:rule, assessment: other_assessment, position: 1)
      expect(rule_in_other_assessment).to be_valid
    end
  end

  describe 'scopes' do
    let!(:rule1) { create(:rule, assessment: assessment, position: 3) }
    let!(:rule2) { create(:rule, assessment: assessment, position: 1) }
    let!(:rule3) { create(:rule, assessment: assessment, position: 2) }

    it 'orders by position' do
      expect(Rule.ordered).to eq([rule2, rule3, rule1])
    end
  end

  describe '#parsed_conditions' do
    let(:rule) { create(:rule, assessment: assessment, conditions: '{"1": {"value": 2}}') }

    it 'parses JSON conditions from text field' do
      expect(rule.parsed_conditions).to eq({ "1" => { "value" => 2 } })
    end

    context 'with invalid JSON' do
      let(:rule) { create(:rule, assessment: assessment, conditions: 'invalid json') }

      it 'returns empty hash for invalid JSON' do
        expect(rule.parsed_conditions).to eq({})
      end
    end
  end

  describe '#parsed_conditions=' do
    let(:rule) { build(:rule, assessment: assessment) }
    let(:conditions_hash) { { question.id => { "value" => 2 } } }

    it 'converts hash to JSON string' do
      rule.parsed_conditions = conditions_hash
      expect(rule.conditions).to eq(conditions_hash.to_json)
    end

    it 'clears memoized parsed_conditions' do
      rule.parsed_conditions = conditions_hash
      expect(rule.parsed_conditions).to eq(conditions_hash.stringify_keys)
    end
  end

  describe '#match?' do
    let(:rule) { create(:rule, assessment: assessment) }

    context 'with empty conditions' do
      before { rule.update(conditions: '{}') }

      it 'returns false' do
        responses = []
        expect(rule.match?(responses)).to be false
      end
    end

    context 'with exact value match condition' do
      before do
        rule.parsed_conditions = { question.id => { "value" => 2 } }
        rule.save
      end

      it 'matches when response has exact value' do
        response = create(:response, contact: contact, question: question, answer: answer2)
        expect(rule.match?([response])).to be true
      end

      it 'does not match when response has different value' do
        response = create(:response, contact: contact, question: question, answer: answer1)
        expect(rule.match?([response])).to be false
      end

      it 'does not match when no response exists' do
        expect(rule.match?([])).to be false
      end
    end

    context 'with range match condition' do
      before do
        rule.parsed_conditions = { question.id => { "range" => [1, 3] } }
        rule.save
      end

      it 'matches when response is within range' do
        response = create(:response, contact: contact, question: question, answer: answer2)
        expect(rule.match?([response])).to be true
      end

      it 'matches when response is at range boundary' do
        response1 = create(:response, contact: contact, question: question, answer: answer1)
        response3 = create(:response, contact: contact, question: question, answer: answer3)
        
        expect(rule.match?([response1])).to be true
        expect(rule.match?([response3])).to be true
      end

      it 'does not match when response is outside range' do
        answer4 = create(:answer, question: question, position: 4)
        response = create(:response, contact: contact, question: question, answer: answer4)
        expect(rule.match?([response])).to be false
      end
    end

    context 'with text contains condition' do
      let(:text_question) { create(:question, assessment: assessment, question_type: 'short_text') }
      
      before do
        rule.parsed_conditions = { text_question.id => { "text_contains" => "agile" } }
        rule.save
      end

      it 'matches when text response contains keyword (case insensitive)' do
        response = create(:response, contact: contact, question: text_question, answer: nil, text_response: "I love Agile methodologies")
        expect(rule.match?([response])).to be true
      end

      it 'does not match when text response does not contain keyword' do
        response = create(:response, contact: contact, question: text_question, answer: nil, text_response: "I prefer waterfall")
        expect(rule.match?([response])).to be false
      end

      it 'does not match when no text response exists' do
        expect(rule.match?([])).to be false
      end
    end

    context 'with any value condition (nil)' do
      before do
        rule.parsed_conditions = { question.id => nil }
        rule.save
      end

      it 'matches when any response exists' do
        response = create(:response, contact: contact, question: question, answer: answer1)
        expect(rule.match?([response])).to be true
      end

      it 'does not match when no response exists' do
        expect(rule.match?([])).to be false
      end
    end

    context 'with multiple conditions' do
      let(:question2) { create(:question, assessment: assessment, question_type: 'radio_button') }
      let(:answer2_1) { create(:answer, question: question2, position: 1) }
      
      before do
        rule.parsed_conditions = { 
          question.id => { "value" => 2 },
          question2.id => { "range" => [1, 2] }
        }
        rule.save
      end

      it 'matches when all conditions are met' do
        response1 = create(:response, contact: contact, question: question, answer: answer2)
        response2 = create(:response, contact: contact, question: question2, answer: answer2_1)
        expect(rule.match?([response1, response2])).to be true
      end

      it 'does not match when only some conditions are met' do
        response1 = create(:response, contact: contact, question: question, answer: answer1) # Wrong value
        response2 = create(:response, contact: contact, question: question2, answer: answer2_1) # Correct
        expect(rule.match?([response1, response2])).to be false
      end

      it 'does not match when no conditions are met' do
        response1 = create(:response, contact: contact, question: question, answer: answer1) # Wrong value
        answer2_3 = create(:answer, question: question2, position: 3)
        response2 = create(:response, contact: contact, question: question2, answer: answer2_3) # Out of range
        expect(rule.match?([response1, response2])).to be false
      end
    end
  end
end