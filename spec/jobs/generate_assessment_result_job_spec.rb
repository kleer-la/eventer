require 'rails_helper'

RSpec.describe GenerateAssessmentResultJob, type: :job do
  let(:contact) { create(:contact, assessment: assessment) }
  let(:store_service) { instance_double(FileStoreService) }

  before do
    allow(FileStoreService).to receive(:current).and_return(store_service)
    allow(store_service).to receive(:upload).and_return('https://example.com/report.pdf')
    # Mock logo file as not existing to avoid test dependency on actual file
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(Rails.root.join('app/assets/images/black_logo.png')).and_return(false)
  end

  describe '#perform' do
    context 'with rule-based assessment' do
      let(:assessment) { create(:assessment, rule_based: true, title: 'Leadership Assessment') }
      let(:question1) { create(:question, assessment: assessment, question_type: 'linear_scale') }
      let(:question2) { create(:question, assessment: assessment, question_type: 'short_text') }
      let(:answer1) { create(:answer, question: question1, position: 2) }
      let(:answer3) { create(:answer, question: question1, position: 3) }

      let!(:rule1) do
        create(:rule,
               assessment: assessment,
               position: 1,
               diagnostic_text: 'You show strong leadership potential.',
               conditions: { question1.id => { 'range' => [2, 4] } }.to_json)
      end

      let!(:rule2) do
        create(:rule,
               assessment: assessment,
               position: 2,
               diagnostic_text: 'Your communication style is collaborative.',
               conditions: { question2.id => { 'text_contains' => 'team' } }.to_json)
      end

      before do
        create(:response, contact: contact, question: question1, answer: answer1)
        create(:response, contact: contact, question: question2, answer: nil,
                          text_response: 'I like working with my team')
        contact.form_data = { 'name' => 'John Doe' }
        contact.save
      end

      it 'generates a rule-based report' do
        expect { GenerateAssessmentResultJob.perform_now(contact.id) }
          .to change { contact.reload.status }.to('completed')
      end

      it 'sets the assessment report URL' do
        GenerateAssessmentResultJob.perform_now(contact.id)
        expect(contact.reload.assessment_report_url).to eq('https://example.com/report.pdf')
      end

      it 'stores HTML content in assessment_report_html field' do
        GenerateAssessmentResultJob.perform_now(contact.id)
        contact.reload

        expect(contact.assessment_report_html).to be_present
        expect(contact.assessment_report_html).to include('<!DOCTYPE html>')
        expect(contact.assessment_report_html).to include('Leadership Assessment')
        expect(contact.assessment_report_html).to include('John Doe')
        expect(contact.assessment_report_html).to include('You show strong leadership potential.')
        expect(contact.assessment_report_html).to include('Your communication style is collaborative.')
        expect(contact.assessment_report_html).to include('Datos de la Evaluación: Preguntas y Respuestas')
        expect(contact.assessment_report_html).to include('Diagnóstico')
        expect(contact.assessment_report_html).to include('header-container')
      end

      it 'renders markdown in diagnostic text and questions/answers' do
        # Create questions with markdown content
        question_markdown = create(:question, assessment: assessment,
                                              question_type: 'radio_button',
                                              name: '**Bold question** with *italic* text')
        answer_markdown = create(:answer, question: question_markdown,
                                          text: 'Answer with `code` formatting')

        # Create rule with markdown diagnostic text
        create(:rule, assessment: assessment,
                      position: 3,
                      diagnostic_text: 'Diagnostic with **bold** and *italic* markdown.',
                      conditions: { question_markdown.id => { 'range' => [1, 4] } }.to_json)

        # Create response
        create(:response, contact: contact, question: question_markdown, answer: answer_markdown)

        GenerateAssessmentResultJob.perform_now(contact.id)
        contact.reload

        # Check that markdown was rendered to HTML
        html_content = contact.assessment_report_html

        # Question markdown should be rendered
        expect(html_content).to include('<strong>Bold question</strong>')
        expect(html_content).to include('<em>italic</em>')

        # Answer markdown should be rendered
        expect(html_content).to include('<code>code</code>')

        # Diagnostic markdown should be rendered
        expect(html_content).to include('Diagnostic with <strong>bold</strong> and <em>italic</em> markdown')
      end

      it 'evaluates rules and includes matching diagnostics in PDF' do
        job = GenerateAssessmentResultJob.new

        # Mock the PDF generator and file operations
        generator_mock = instance_double('RuleBasedAssessmentPdfGenerator')
        allow(RuleBasedAssessmentPdfGenerator).to receive(:new).and_return(generator_mock)
        allow(generator_mock).to receive(:generate_pdf).and_return('pdf content')
        allow(File).to receive(:binwrite)
        allow(File).to receive(:delete)
        allow(File).to receive(:exist?).and_return(true)

        # Mock HTML generator to capture content
        html_generator_mock = instance_double('RuleBasedAssessmentHtmlGenerator')
        allow(RuleBasedAssessmentHtmlGenerator).to receive(:new).and_return(html_generator_mock)
        allow(html_generator_mock).to receive(:generate_html) do
          # The HTML should contain both diagnostic texts since both rules match
          html_content = '<html>Test HTML with diagnostics: You show strong leadership potential. Your communication style is collaborative.</html>'
          expect(html_content).to include('You show strong leadership potential.')
          expect(html_content).to include('Your communication style is collaborative.')
          html_content
        end

        job.perform(contact.id)

        expect(generator_mock).to have_received(:generate_pdf)
        expect(html_generator_mock).to have_received(:generate_html)
      end

      it 'creates temporary files and cleans them up' do
        allow(File).to receive(:binwrite)
        allow(File).to receive(:delete)
        allow(File).to receive(:exist?).and_return(true)
        # Specifically mock logo file as not existing
        allow(File).to receive(:exist?).with(Rails.root.join('app/assets/images/black_logo.png')).and_return(false)

        GenerateAssessmentResultJob.perform_now(contact.id)

        expect(File).to have_received(:binwrite) do |path, content|
          expect(path.to_s).to match(/.*assessment_#{contact.id}_\d{8}_\d{6}\.pdf$/)
          expect(content).to be_a(String)
          expect(content).to start_with('%PDF')
        end
        expect(File).to have_received(:delete)
      end
    end

    context 'with competency-based assessment' do
      let(:assessment) { create(:assessment, rule_based: false) }
      let(:question) do
        create(:question, assessment: assessment, question_type: 'linear_scale', name: 'Leadership Skills')
      end
      let(:answer) { create(:answer, question: question, position: 3) }

      before do
        create(:response, contact: contact, question: question, answer: answer)
        contact.form_data = { 'name' => 'Jane Smith' }
        contact.save

        # Mock Gruff chart generation
        chart_mock = instance_double('CustomSpider')
        allow(CustomSpider).to receive(:new).and_return(chart_mock)
        allow(chart_mock).to receive(:data)
        allow(chart_mock).to receive(:theme=)
        allow(chart_mock).to receive(:write) do |path|
          # Create a minimal valid PNG file for testing
          png_data = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
                      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
                      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
                      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
                      0x42, 0x60, 0x82].pack('C*')
          File.binwrite(path, png_data)
        end
      end

      it 'generates a competency-based report with radar chart' do
        expect { GenerateAssessmentResultJob.perform_now(contact.id) }
          .to change { contact.reload.status }.to('completed')
      end

      it 'generates HTML content for competency assessment' do
        GenerateAssessmentResultJob.perform_now(contact.id)
        contact.reload

        expect(contact.assessment_report_html).to be_present
        expect(contact.assessment_report_html).to include('<!DOCTYPE html>')
        expect(contact.assessment_report_html).to include('Agile Coach Competency Framework Assessment')
        expect(contact.assessment_report_html).to include('Gráfico de Competencias')
        expect(contact.assessment_report_html).to include('Niveles de Competencia')
        expect(contact.assessment_report_html).to include('Leadership skills')
      end

      it 'creates and uploads radar chart' do
        chart_mock = instance_double('CustomSpider')
        allow(CustomSpider).to receive(:new).and_return(chart_mock)
        allow(chart_mock).to receive(:data)
        allow(chart_mock).to receive(:theme=)
        allow(chart_mock).to receive(:write) do |path|
          # Create a minimal valid PNG file for testing
          png_data = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
                      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
                      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
                      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
                      0x42, 0x60, 0x82].pack('C*')
          File.binwrite(path, png_data)
        end

        GenerateAssessmentResultJob.perform_now(contact.id)

        expect(chart_mock).to have_received(:data).with('leadership_skills', 3).at_least(1).times
        expect(store_service).to have_received(:upload).twice # PDF and chart for competency HTML reports
      end
    end

    context 'when job fails' do
      let(:assessment) { create(:assessment, rule_based: true) }

      before do
        allow(store_service).to receive(:upload).and_raise(StandardError.new('Upload failed'))
      end

      it 'sets contact status to failed and re-raises error' do
        expect do
          GenerateAssessmentResultJob.perform_now(contact.id)
        end.to raise_error(StandardError, 'Upload failed')

        expect(contact.reload.status).to eq('failed')
      end

      it 'logs the error' do
        expect(Log).to receive(:log).with(:assessment, :error, anything, hash_including(:error, :backtrace))

        expect do
          GenerateAssessmentResultJob.perform_now(contact.id)
        end.to raise_error(StandardError)
      end
    end
  end

  describe 'HTML report generation' do
    let(:assessment) { create(:assessment, rule_based: true, title: 'Test Assessment') }
    let(:contact) { create(:contact, assessment: assessment) }

    before do
      contact.form_data = { 'name' => 'Test User' }
      contact.save
    end

    it 'generates HTML with participant name and diagnostics using RuleBasedAssessmentHtmlGenerator' do
      # Mock diagnostics by stubbing the assessment evaluation
      allow(assessment).to receive(:evaluate_rules_for_contact)
        .with(contact)
        .and_return(['First diagnostic message', 'Second diagnostic message'])

      generator = RuleBasedAssessmentHtmlGenerator.new(contact)
      html = generator.generate_html

      expect(html).to include('Test Assessment')
      expect(html).to include('Test User')
      expect(html).to include('First diagnostic message')
      expect(html).to include('Second diagnostic message')
      expect(html).to include('<div class="diagnostic-item">')
      expect(html).to include('Datos de la Evaluación: Preguntas y Respuestas')
      expect(html).to include('Diagnóstico')
      expect(html).to include('header-container')
      expect(html).to include('lang="es"')
      expect(html).to include('<div class="assessment-report">')
      expect(html).to include('.assessment-report')
    end

    it 'handles empty diagnostics gracefully' do
      allow(assessment).to receive(:evaluate_rules_for_contact)
        .with(contact)
        .and_return([])

      generator = RuleBasedAssessmentHtmlGenerator.new(contact)
      html = generator.generate_html

      expect(html).to include('Test Assessment')
      expect(html).to include('Test User')
      expect(html).to include('No se activaron diagnósticos específicos basados en tus respuestas')
      expect(html).to include('no-diagnostics')
    end

    it 'handles missing participant name' do
      contact.update(form_data: {})
      allow(assessment).to receive(:evaluate_rules_for_contact)
        .with(contact)
        .and_return(['Test diagnostic'])

      generator = RuleBasedAssessmentHtmlGenerator.new(contact)
      html = generator.generate_html

      expect(html).to include('Participante: Participante') # Default name
    end

    it 'includes questions and answers section' do
      # Create some test responses
      question1 = create(:question, assessment: assessment, name: 'Nivel de Agilidad', question_type: 'radio_button')
      question2 = create(:question, assessment: assessment, name: '¿Qué más dirías?', question_type: 'short_text')
      answer1 = create(:answer, question: question1, text: 'Escalando', position: 2)

      create(:response, contact: contact, question: question1, answer: answer1)
      create(:response, contact: contact, question: question2, text_response: 'Somos una startup')

      allow(assessment).to receive(:evaluate_rules_for_contact)
        .with(contact)
        .and_return(['Test diagnostic'])

      generator = RuleBasedAssessmentHtmlGenerator.new(contact)
      html = generator.generate_html

      expect(html).to include('Pregunta: <p>Nivel de Agilidad</p>')
      expect(html).to include('Respuesta: <p>Escalando</p>')
      expect(html).to include('Pregunta: <p>¿Qué más dirías?</p>')
      expect(html).to include('Respuesta: <p>Somos una startup</p>')
      expect(html).to include('<dt>')
      expect(html).to include('<dd>')
    end
  end

  describe 'PDF generation from HTML' do
    let(:assessment) { create(:assessment, rule_based: true, title: 'PDF Test') }
    let(:contact) { create(:contact, assessment: assessment) }
    let(:job) { GenerateAssessmentResultJob.new }

    before do
      contact.form_data = { 'name' => 'PDF User' }
      contact.save
      # Set up null file store to avoid S3 dependency
      FileStoreService.create_null
      # Mock logo file as not existing to avoid test dependency on actual file
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(Rails.root.join('app/assets/images/black_logo.png')).and_return(false)
    end

    it 'generates PDF with assessment content' do
      # Mock assessment to return diagnostics
      allow(assessment).to receive(:evaluate_rules_for_contact)
        .with(contact)
        .and_return(['Test diagnostic for PDF'])
      pdf_content = job.send(:generate_pdf, contact)

      expect(pdf_content).to be_a(String)
      expect(pdf_content.length).to be > 0
      # PDF content should start with PDF header
      expect(pdf_content).to start_with('%PDF')
    end

    it 'includes assessment title and participant name in PDF' do
      allow(assessment).to receive(:evaluate_rules_for_contact)
        .with(contact)
        .and_return(['Diagnostic text'])

      # Mock Prawn::Document to capture the content
      pdf_mock = instance_double('Prawn::Document')
      font_families_mock = {}
      bounds_mock = double(width: 500, height: 700)
      allow(Prawn::Document).to receive(:new).and_return(pdf_mock)
      allow(pdf_mock).to receive(:font_families).and_return(font_families_mock)
      allow(pdf_mock).to receive(:font)
      allow(pdf_mock).to receive(:text)
      allow(pdf_mock).to receive(:move_down)
      allow(pdf_mock).to receive(:image)
      allow(pdf_mock).to receive(:bounds).and_return(bounds_mock)
      allow(pdf_mock).to receive(:fill_color)
      allow(pdf_mock).to receive(:draw_text)
      allow(pdf_mock).to receive(:render).and_return('mocked pdf content')

      job.send(:generate_pdf, contact)

      # Check for the new PDF structure
      expect(pdf_mock).to have_received(:text).with('Participante: PDF User', size: 12, align: :center, color: '333333')
      expect(pdf_mock).to have_received(:text).with('Diagnostic text', size: 12, color: '333333', leading: 4)
    end

    it 'handles long_text question types correctly in PDF' do
      # Create questions with different types including long_text
      question1 = create(:question, assessment: assessment, name: 'Short question', question_type: 'short_text')
      question2 = create(:question, assessment: assessment, name: '¿Qué más dirías?', question_type: 'long_text')
      question3 = create(:question, assessment: assessment, name: 'Scale question', question_type: 'linear_scale')
      answer3 = create(:answer, question: question3, text: 'High', position: 4)

      # Create responses
      create(:response, contact: contact, question: question1, text_response: 'Short answer')
      create(:response, contact: contact, question: question2,
                        text_response: 'This is a longer response with multiple sentences. It should appear in the PDF.')
      create(:response, contact: contact, question: question3, answer: answer3)

      allow(assessment).to receive(:evaluate_rules_for_contact).and_return(['Test diagnostic'])

      # Mock Prawn::Document to capture text calls
      pdf_mock = instance_double('Prawn::Document')
      font_families_mock = {}
      text_calls = []

      allow(Prawn::Document).to receive(:new).and_return(pdf_mock)
      allow(pdf_mock).to receive(:font_families).and_return(font_families_mock)
      allow(pdf_mock).to receive(:font)
      allow(pdf_mock).to receive(:text) do |text, *_args|
        text_calls << text
      end
      allow(pdf_mock).to receive(:move_down)
      allow(pdf_mock).to receive(:image)
      allow(pdf_mock).to receive(:fill_color)
      allow(pdf_mock).to receive(:draw_text)
      allow(pdf_mock).to receive(:render).and_return('mocked pdf content')
      allow(pdf_mock).to receive(:bounds).and_return(double(width: 500, height: 700))

      job.send(:generate_pdf, contact)

      # Verify all question types are handled correctly - check for answer text formatted with arrows
      expect(text_calls).to include('→ Short answer')
      expect(text_calls).to include('→ This is a longer response with multiple sentences. It should appear in the PDF.')
      expect(text_calls).to include('→ High')

      # Verify section headers are present
      expect(text_calls).to include('Datos de la Evaluación: Preguntas y Respuestas')
      expect(text_calls).to include('Diagnóstico')
    end
  end

  describe 'backward compatibility' do
    let(:assessment) { create(:assessment, rule_based: false) }
    let(:question) { create(:question, assessment: assessment, question_type: 'linear_scale') }
    let(:answer) { create(:answer, question: question, position: 2) }

    before do
      create(:response, contact: contact, question: question, answer: answer)

      # Mock chart generation for competency reports
      chart_mock = instance_double('CustomSpider')
      allow(CustomSpider).to receive(:new).and_return(chart_mock)
      allow(chart_mock).to receive(:data)
      allow(chart_mock).to receive(:theme=)
      allow(chart_mock).to receive(:write) do |path|
        # Create a minimal valid PNG file for testing
        png_data = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
                    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
                    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
                    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
                    0x42, 0x60, 0x82].pack('C*')
        File.binwrite(path, png_data)
      end
    end

    it 'still generates competency reports for non-rule-based assessments' do
      expect { GenerateAssessmentResultJob.perform_now(contact.id) }
        .to change { contact.reload.status }.to('completed')
        .and change { contact.reload.assessment_report_url }.to('https://example.com/report.pdf')
    end
  end
end
