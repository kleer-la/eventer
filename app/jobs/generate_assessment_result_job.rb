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
    # Generate competency data for both PDF and HTML
    competencies = fetch_key_value_from_responses(contact)

    # Ensure we have at least 3 data points for the spider chart
    competencies["placeholder_#{competencies.size}"] = 0 while competencies.size < 3 if competencies.size < 3

    # Generate and store the radar chart
    chart_path = generate_and_store_radar_chart(contact, competencies, store, file_name)

    # Generate PDF using shared generator
    generator = CompetencyAssessmentPdfGenerator.new(contact)
    pdf_content = generator.generate_pdf

    # Generate HTML content for competency assessment
    html_content = generate_competency_html_report(contact, competencies, chart_path)

    # Save PDF to temporary file and upload
    pdf_file_name = "#{file_name}.pdf"
    pdf_path = Rails.root.join('tmp', pdf_file_name)

    File.binwrite(pdf_path, pdf_content)
    pdf_url = store.upload(pdf_path, pdf_file_name, 'certificate')

    # Update contact with both PDF URL and HTML content
    contact.update(
      assessment_report_url: pdf_url,
      assessment_report_html: html_content,
      status: :completed
    )

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
  def generate_pdf(contact)
    generator = RuleBasedAssessmentPdfGenerator.new(contact)
    generator.generate_pdf
  end

  # Generate and store radar chart for competency assessments
  def generate_and_store_radar_chart(contact, competencies, store, file_name)
    # Generate the radar chart using Gruff
    require 'gruff'
    g = CustomSpider.new(5)
    competencies.each do |key, value|
      g.data(key, value)
    end
    g.theme = {
      colors: %w[white white white white white white white],
      marker_color: 'pink',
      font_color: 'black',
      background_colors: %w[white white]
    }

    # Save chart to temporary file
    chart_temp_path = Rails.root.join('tmp', "radar_chart_#{contact.id}.png")
    g.write(chart_temp_path)

    # Upload chart to file storage for persistent access
    chart_file_name = "#{file_name}_chart.png"
    chart_url = store.upload(chart_temp_path, chart_file_name, 'certificate')

    # Clean up temporary chart file
    File.delete(chart_temp_path) if File.exist?(chart_temp_path)

    chart_url
  end

  def fetch_key_value_from_responses(contact)
    contact.responses.includes(:question, :answer).reduce({}) do |ac, response|
      question_name = response.question.name.downcase.gsub(/\s+/, '_')

      case response.question.question_type
      when 'linear_scale', 'radio_button'
        if response.answer.present?
          position = (response.answer.position || 0).to_i
          normalized_score = position
          ac.merge(question_name => normalized_score)
        else
          ac # Skip if no answer
        end
      when 'short_text', 'long_text'
        ac # Skip text responses from radar chart for now
      else
        ac # Skip unknown question types
      end
    end
  end

  # Generate HTML report for competency assessments
  def generate_competency_html_report(contact, competencies, chart_url)
    # Set locale for HTML generation
    locale = contact.assessment.language || contact.form_data&.dig('language') || 'es'
    I18n.with_locale(locale) do
      name = contact.form_data&.dig('name') || I18n.t('assessment.pdf.participant_default', default: 'Participante')
      company = contact.form_data&.dig('company') || ''
      assessment_title = 'Agile Coach Competency Framework Assessment'
      assessment_language = contact.assessment.language || 'es'
      assessment_date = I18n.l(contact.created_at, format: :long)

      # Get questions and answers
      questions_and_answers = get_questions_and_answers(contact)

      # Generate competency levels text
      competency_levels_html = ''
      competencies.each do |key, value|
        next if key.to_s.start_with?('placeholder_')

        level = case value
                when 0 then I18n.t('competency.level.novice', default: 'Novato')
                when 1 then I18n.t('competency.level.beginner', default: 'Principiante')
                when 2 then I18n.t('competency.level.intermediate', default: 'Intermedio')
                when 3 then I18n.t('competency.level.advanced', default: 'Avanzado')
                when 4 then I18n.t('competency.level.expert', default: 'Experto')
                else I18n.t('competency.level.novice', default: 'Novato')
                end
        competency_levels_html += "<li><strong>#{key.to_s.humanize}:</strong> #{level}</li>\n"
      end

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
              background-color: #2D5A5A;
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
              color: #2D5A5A;
              font-size: 1.4em;
              margin-top: 20px;
              margin-bottom: 15px;
            }

            .assessment-report p {
              margin: 5px 0;
              line-height: 1.4;
            }

            .assessment-report ul {
              margin: 10px 0;
              padding-left: 20px;
            }

            .assessment-report li {
              margin-bottom: 8px;
              line-height: 1.4;
            }

            .assessment-report footer {
              text-align: center;
              font-size: 0.8em;
              color: #777;
              border-top: 1px solid #ddd;
              padding-top: 10px;
              margin-top: 30px;
            }

            .radar-chart {
              text-align: center;
              margin: 30px 0;
            }

            .radar-chart img {
              max-width: 100%;
              height: auto;
              border: 1px solid #ddd;
              border-radius: 8px;
            }

            .competency-levels {
              background-color: #f8f9fa;
              padding: 20px;
              border-radius: 8px;
              margin: 20px 0;
            }

            .assessment-report img {
              max-width: 100%;
              height: auto;
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

            <!-- Radar Chart -->
            <section id="chart">
              <h2>#{I18n.t('assessment.competency.radar_chart', default: 'Gráfico de Competencias')}</h2>
              <div class="radar-chart">
                <img src="#{chart_url}" alt="#{I18n.t('assessment.competency.radar_chart', default: 'Gráfico de Competencias')}" 
                     onerror="this.style.display='none'; this.nextElementSibling.style.display='block';" />
                <div style="display: none; padding: 20px; background-color: #f8f9fa; border: 1px solid #ddd; border-radius: 8px; text-align: center; color: #666;">
                  <p>#{I18n.t('assessment.competency.chart_unavailable', default: 'El gráfico de competencias no está disponible en este momento.')}</p>
                  <p style="font-size: 0.9em;">#{I18n.t('assessment.competency.see_levels_below', default: 'Los niveles de competencia se muestran a continuación.')}</p>
                </div>
              </div>
            </section>

            <!-- Assessment Data: Questions and Answers -->
            <section id="data">
              <h2>#{I18n.t('assessment.pdf.questions_and_answers')}</h2>
              <dl>
                #{questions_and_answers}
              </dl>
            </section>

            <!-- Competency Levels -->
            <section id="levels">
              <h2>#{I18n.t('assessment.competency.levels', default: 'Niveles de Competencia')}</h2>
              <div class="competency-levels">
                <ul>
                  #{competency_levels_html}
                </ul>
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
end
