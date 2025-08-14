# app/jobs/generate_assessment_result_job.rb
class GenerateAssessmentResultJob < ActiveJob::Base
  include ApplicationHelper
  queue_as :default

  def perform(contact_id)
    contact = Contact.find(contact_id)
    contact.update(status: :in_progress)
    store = FileStoreService.current
    file_name = "assessment_#{contact_id}_#{Time.now.strftime('%Y%m%d_%H%M%S')}"

    begin
      assessment = contact.assessment

      if assessment.rule_based?
        generate_rule_based_report(contact, store, file_name)
      else
        generate_competency_report(contact, store, file_name)
      end
      Log.log(:assessment, :info, "PDF generated for contact #{contact_id}",
              { public_url: contact.assessment_report_url })
    rescue StandardError => e
      contact.update(status: :failed)
      Log.log(:assessment, :error, "Failed to generate PDF for contact #{contact_id}",
              { error: e.message, backtrace: e.backtrace })
      raise e
    end
  end

  private

  def markdown_to_text(text)
    # Convert markdown to HTML then strip HTML tags for plain text
    return '' if text.nil?

    html = markdown(text)
    ActionView::Base.full_sanitizer.sanitize(html).strip
  end

  def generate_rule_based_report(contact, store, file_name)
    # Generate PDF using shared generator
    generator = RuleBasedAssessmentPdfGenerator.new(contact)
    pdf_content = generator.generate_pdf

    # Generate HTML content for compatibility
    assessment = contact.assessment
    diagnostics = assessment.evaluate_rules_for_contact(contact)
    html_content = generate_html_report(contact, diagnostics)

    # Save PDF to temporary file and upload
    pdf_file_name = "#{file_name}.pdf"
    pdf_path = Rails.root.join('tmp', pdf_file_name)

    File.binwrite(pdf_path, pdf_content)
    public_url = store.upload(pdf_path, pdf_file_name, 'certificate')

    # Update contact with both PDF URL and HTML content
    contact.update(
      assessment_report_url: public_url,
      assessment_report_html: html_content,
      status: :completed
    )

    # Clean up temporary file
    File.delete(pdf_path) if File.exist?(pdf_path)
  end

  def generate_competency_report(contact, store, file_name)
    # Generate PDF using shared generator
    generator = CompetencyAssessmentPdfGenerator.new(contact)
    pdf_content = generator.generate_pdf

    # Save PDF to temporary file and upload
    pdf_file_name = "#{file_name}.pdf"
    pdf_path = Rails.root.join('tmp', pdf_file_name)

    File.binwrite(pdf_path, pdf_content)
    public_url = store.upload(pdf_path, pdf_file_name, 'certificate')
    
    contact.update(assessment_report_url: public_url, status: :completed)

    # Clean up temporary files
    File.delete(pdf_path) if File.exist?(pdf_path)
  end

  def generate_html_report(contact, diagnostics)
    # Set locale for HTML generation
    locale = contact.assessment.language || contact.form_data&.dig('language') || 'es'
    I18n.with_locale(locale) do
      name = contact.form_data&.dig('name') || I18n.t('assessment.pdf.participant_default', default: 'Participante')
      company = contact.form_data&.dig('company') || ''
      assessment_title = contact.assessment.title
      assessment_language = contact.assessment.language || 'es'
      assessment_date = contact.created_at.strftime('%B %d, %Y')

      # Get questions and answers
      questions_and_answers = get_questions_and_answers(contact)

      html = <<~HTML
        <!DOCTYPE html>
        <html lang="#{assessment_language}">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>#{assessment_title} - Reporte de Evaluación</title>
          <style>
            .assessment-report {
              font-family: Arial, sans-serif;
              margin: 20px;
              color: #333;
              max-width: 800px;
              margin: 0 auto;
            }

            .assessment-report header {
              background-color: #007BFF;
              color: white;
              padding: 20px;
              text-align: center;
            }

            .assessment-report section {
              margin: 20px 0;
            }

            .assessment-report h1 {
              margin: 0;
              color: white;
              font-size: 1.8em;
            }

            .assessment-report h2 {
              color: #007BFF;
              font-size: 1.4em;
              margin-top: 20px;
              margin-bottom: 15px;
            }

            .assessment-report p {
              margin: 5px 0;
              line-height: 1.4;
            }

            .assessment-report dl {
              margin: 10px 0;
            }

            .assessment-report dt {
              font-weight: bold;
              margin-top: 10px;
              color: #333;
            }

            .assessment-report dd {
              margin-left: 20px;
              margin-bottom: 8px;
              color: #555;
            }

            .assessment-report footer {
              text-align: center;
              font-size: 0.8em;
              color: #777;
              border-top: 1px solid #ddd;
              padding-top: 10px;
              margin-top: 30px;
            }

            .assessment-report .diagnostic-section {
              background-color: #f8f9fa;
              padding: 20px;
              border-radius: 8px;
              margin: 20px 0;
            }

            .assessment-report .diagnostic-item {
              margin-bottom: 15px;
              padding: 10px;
              background-color: white;
              border-left: 4px solid #007BFF;
              border-radius: 4px;
              line-height: 1.5;
            }

            .assessment-report .no-diagnostics {
              text-align: center;
              color: #6c757d;
              font-style: italic;
              padding: 20px;
            }

            .assessment-report img {
              max-width: 100%;
              height: auto;
            }
          </style>
        </head>

        <body>
          <div class="assessment-report">
            <header>
              <img src="https://www.kleer.la/app/img/black_logo.webp" alt="Kleer Logo"
                style="max-width: 200px; margin-bottom: 10px;">
              <h1>#{assessment_title}</h1>
              <p>#{I18n.t('assessment.pdf.participant')} #{name}</p>
              #{company.present? ? "<p>#{I18n.t('assessment.pdf.company')} #{company}</p>" : ''}
              <p>#{I18n.t('assessment.pdf.assessment_date')} #{assessment_date}</p>
            </header>

            <!-- Assessment Data: Questions and Answers -->
            <section id="data">
              <h2>#{I18n.t('assessment.pdf.questions_and_answers')}</h2>
              <dl>
                #{questions_and_answers}
              </dl>
            </section>

            <!-- Diagnostic Results -->
            <section id="insights">
              <h2>#{I18n.t('assessment.pdf.diagnosis')}</h2>
              <div class="diagnostic-section">
      HTML

      if diagnostics.any?
        diagnostics.each do |diagnostic|
          html += "<div class=\"diagnostic-item\">#{markdown(diagnostic)}</div>\n"
        end
      else
        html += "<div class=\"no-diagnostics\">#{I18n.t('no_specific_diagnostics',
                                                        default: 'No se activaron diagnósticos específicos basados en tus respuestas.')}</div>\n"
      end

      html += <<~HTML
              </div>
            </section>

            <!-- Footer -->
            <footer>
              <p>#{I18n.t('assessment.pdf.footer_disclaimer')}</p>
            </footer>
          </div>
        </body>
        </html>
      HTML

      html
    end
  end

  def get_questions_and_answers(contact)
    return '' unless contact.responses.any?

    questions_html = ''
    contact.responses.includes(:question, :answer).each do |response|
      question_text = response.question.name || response.question.text || "#{I18n.t('question',
                                                                                    default: 'Pregunta')} #{response.question.id}"

      answer_text = case response.question.question_type
                    when 'linear_scale', 'radio_button'
                      if response.answer.present?
                        response.answer.text.presence || "#{I18n.t('option',
                                                                   default: 'Opción')} #{response.answer.position}"
                      else
                        I18n.t('no_response', default: 'Sin respuesta')
                      end
                    when 'short_text', 'long_text'
                      response.text_response.presence || I18n.t('no_response', default: 'Sin respuesta')
                    else
                      I18n.t('question_type_not_recognized', default: 'Tipo de pregunta no reconocido')
                    end

      questions_html += "<dt>#{I18n.t('question', default: 'Pregunta')}: #{markdown(question_text)}</dt>\n"
      questions_html += "<dd>#{I18n.t('answer', default: 'Respuesta')}: #{markdown(answer_text)}</dd>\n"
    end

    questions_html
  end

  # Legacy method for test compatibility
  def generate_pdf_from_html(html_content, contact)
    generator = RuleBasedAssessmentPdfGenerator.new(contact)
    generator.generate_pdf
  end
end