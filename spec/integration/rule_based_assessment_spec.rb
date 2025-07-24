require 'rails_helper'

RSpec.describe 'Rule-based Assessment Integration', type: :feature do
  let(:assessment) { create(:assessment, :rule_based, title: 'Leadership Assessment') }
  let(:question1) { create(:question, assessment: assessment, question_type: 'linear_scale', name: 'Decision Making') }
  let(:question2) { create(:question, assessment: assessment, question_type: 'short_text', name: 'Leadership Style') }
  let(:question3) { create(:question, assessment: assessment, question_type: 'radio_button', name: 'Team Size') }

  let!(:answers1) do
    [
      create(:answer, question: question1, text: 'Poor', position: 1),
      create(:answer, question: question1, text: 'Good', position: 2),
      create(:answer, question: question1, text: 'Excellent', position: 3)
    ]
  end

  let!(:answers3) do
    [
      create(:answer, question: question3, text: 'Small (1-5)', position: 1),
      create(:answer, question: question3, text: 'Medium (6-15)', position: 2),
      create(:answer, question: question3, text: 'Large (16+)', position: 3)
    ]
  end

  let!(:rule1) do
    create(:rule,
           assessment: assessment,
           position: 1,
           diagnostic_text: 'You demonstrate strong decision-making capabilities.',
           conditions: { question1.id => { 'range' => [2, 3] } }.to_json)
  end

  let!(:rule2) do
    create(:rule,
           assessment: assessment,
           position: 2,
           diagnostic_text: 'Your collaborative approach is well-suited for team leadership.',
           conditions: { question2.id => { 'text_contains' => 'collaborative' } }.to_json)
  end

  let!(:rule3) do
    create(:rule,
           assessment: assessment,
           position: 3,
           diagnostic_text: 'You have experience managing large teams.',
           conditions: { question3.id => { 'value' => 3 } }.to_json)
  end

  let!(:rule4) do
    create(:rule,
           assessment: assessment,
           position: 4,
           diagnostic_text: 'You show potential for senior leadership roles.',
           conditions: {
             question1.id => { 'value' => 3 },
             question3.id => { 'range' => [2, 3] }
           }.to_json)
  end

  describe 'Complete assessment workflow' do
    let(:contact) { create(:contact, assessment: assessment) }
    let(:store_service) { instance_double(FileStoreService) }

    before do
      allow(FileStoreService).to receive(:current).and_return(store_service)
      allow(store_service).to receive(:upload).and_return('https://example.com/report.pdf')

      contact.form_data = { 'name' => 'John Smith' }
      contact.save
    end

    context 'when participant shows strong leadership' do
      before do
        # Create responses that match multiple rules
        create(:response, contact: contact, question: question1, answer: answers1[2]) # Excellent (position 3)
        create(:response, contact: contact, question: question2, answer: nil,
                          text_response: 'I prefer a collaborative approach to leadership')
        create(:response, contact: contact, question: question3, answer: answers3[2]) # Large team (position 3)
      end

      it 'evaluates all matching rules and generates comprehensive report' do
        diagnostics = assessment.evaluate_rules_for_contact(contact)

        expect(diagnostics).to include(
          'You demonstrate strong decision-making capabilities.', # rule1: decision making range [2,3]
          'Your collaborative approach is well-suited for team leadership.', # rule2: text contains "collaborative"
          'You have experience managing large teams.',              # rule3: team size value 3
          'You show potential for senior leadership roles.'         # rule4: excellent decision + large team
        )
        expect(diagnostics.length).to eq(4)
      end

      it 'generates PDF report with all matching diagnostics' do
        allow(File).to receive(:write)
        allow(File).to receive(:delete)
        allow(File).to receive(:exist?).and_return(true)

        GenerateAssessmentResultJob.perform_now(contact.id)

        expect(contact.reload.status).to eq('completed')
        expect(contact.assessment_report_url).to eq('https://example.com/report.pdf')
        expect(store_service).to have_received(:upload) do |path, filename, bucket|
          expect(path.to_s).to match(/.*assessment_#{contact.id}_\d{8}_\d{6}\.pdf$/)
          expect(filename).to match(/assessment_#{contact.id}_\d{8}_\d{6}\.pdf$/)
          expect(bucket).to eq('certificate')
        end
      end
    end

    context 'when participant shows mixed results' do
      before do
        # Create responses that match only some rules
        create(:response, contact: contact, question: question1, answer: answers1[1]) # Good (position 2)
        create(:response, contact: contact, question: question2, answer: nil,
                          text_response: 'I use a directive leadership style')
        create(:response, contact: contact, question: question3, answer: answers3[0]) # Small team (position 1)
      end

      it 'evaluates only matching rules' do
        diagnostics = assessment.evaluate_rules_for_contact(contact)

        expect(diagnostics).to include(
          'You demonstrate strong decision-making capabilities.' # rule1: decision making range [2,3] - matches position 2
        )
        expect(diagnostics).not_to include(
          'Your collaborative approach is well-suited for team leadership.', # rule2: no "collaborative" in text
          'You have experience managing large teams.',              # rule3: small team, not large
          'You show potential for senior leadership roles.'         # rule4: not excellent + not large team
        )
        expect(diagnostics.length).to eq(1)
      end
    end

    context 'when participant matches no rules' do
      before do
        # Create responses that match no rules
        create(:response, contact: contact, question: question1, answer: answers1[0]) # Poor (position 1)
        create(:response, contact: contact, question: question2, answer: nil, text_response: 'I am new to leadership')
        create(:response, contact: contact, question: question3, answer: answers3[0]) # Small team (position 1)
      end

      it 'returns empty diagnostics array' do
        diagnostics = assessment.evaluate_rules_for_contact(contact)
        expect(diagnostics).to be_empty
      end

      it 'generates report with "no diagnostics" message' do
        job = GenerateAssessmentResultJob.new
        html = job.send(:generate_html_report, contact, [])

        expect(html).to include('No se activaron diagnósticos específicos basados en tus respuestas')
      end
    end
  end

  describe 'Rule validation and error handling' do
    it 'handles invalid JSON conditions gracefully' do
      rule = create(:rule, assessment: assessment, position: 10, conditions: 'invalid json')
      expect(rule.parsed_conditions).to eq({})
      expect(rule.match?([])).to be false
    end

    it 'prevents duplicate positions within same assessment' do
      clean_assessment = create(:assessment, :rule_based)
      existing_rule = create(:rule, assessment: clean_assessment, position: 1)
      duplicate_rule = build(:rule, assessment: clean_assessment, position: 1)

      expect(duplicate_rule).not_to be_valid
      expect(duplicate_rule.errors[:position]).to include('ya está en uso')
    end

    it 'allows same position across different assessments' do
      assessment1 = create(:assessment, :rule_based)
      assessment2 = create(:assessment, :rule_based)
      rule1 = create(:rule, assessment: assessment1, position: 1)
      rule2 = build(:rule, assessment: assessment2, position: 1)

      expect(rule2).to be_valid
    end
  end

  describe 'Assessment language consistency' do
    let(:english_assessment) { create(:assessment, :rule_based, :english) }
    let(:spanish_assessment) { create(:assessment, :rule_based, :spanish) }

    it 'maintains language consistency within assessment rules' do
      english_rule = create(:rule, assessment: english_assessment, diagnostic_text: 'English diagnostic')
      spanish_rule = create(:rule, assessment: spanish_assessment, diagnostic_text: 'Diagnóstico en español')

      expect(english_assessment.language).to eq('en')
      expect(spanish_assessment.language).to eq('es')
      expect(english_rule.assessment.language).to eq('en')
      expect(spanish_rule.assessment.language).to eq('es')
    end
  end
end
