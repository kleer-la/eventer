# app/jobs/generate_assessment_result_job.rb
class GenerateAssessmentResultJob < ActiveJob::Base
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

  def generate_rule_based_report(contact, store, file_name)
    assessment = contact.assessment

    # Evaluate rules and get matching diagnostics
    diagnostics = assessment.evaluate_rules_for_contact(contact)

    # Generate HTML content
    html_content = generate_html_report(contact, diagnostics)

    # Generate PDF from HTML
    pdf_content = generate_pdf_from_html(html_content, contact)

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
    # Original competency-based report logic
    competencies = fetch_key_value_from_responses(contact)

    # Ensure we have at least 3 data points for the spider chart
    competencies["placeholder_#{competencies.size}"] = 0 while competencies.size < 3 if competencies.size < 3

    # Generate the radar chart using Gruff
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

    chart_path = Rails.root.join('tmp', "radar_chart_#{contact.id}.png")
    g.write(chart_path)

    # Upload radar chart PNG to the certificate bucket
    chart_public_url = store.upload(chart_path, "#{file_name}.png", 'certificate')

    # Generate PDF using Prawn
    require 'prawn'
    pdf_file_name = "#{file_name}.pdf"
    pdf_path = Rails.root.join('tmp', pdf_file_name)

    name = contact.form_data&.dig('name')
    Prawn::Document.generate(pdf_path) do |pdf|
      pdf.text 'Agile Coach Competency Framework Assessment', size: 24, style: :bold, align: :center
      pdf.text "Name: #{name}", size: 18, align: :center

      # Add the radar chart
      pdf.image chart_path, width: 400, align: :center

      # Add competency levels as a list (excluding placeholder entries)
      pdf.move_down 20
      pdf.text 'Competency Levels:', size: 16, style: :bold
      competencies.each do |key, value|
        next if key.to_s.start_with?('placeholder_')

        level = case value
                when 0 then 'Novato'
                when 1 then 'Principiante'
                when 2 then 'Intermedio'
                when 3 then 'Avanzado'
                when 4 then 'Experto'
                else 'Novato'
                end
        pdf.text "#{key.to_s.humanize}: #{level}", indent_paragraphs: 20
      end
    end

    public_url = store.upload(pdf_path, pdf_file_name, 'certificate')
    contact.update(assessment_report_url: public_url, status: :completed)

    # Clean up temporary files
    File.delete(chart_path) if File.exist?(chart_path)
    File.delete(pdf_path) if File.exist?(pdf_path)
  end

  def generate_html_report(contact, diagnostics)
    name = contact.form_data&.dig('name') || 'Participante'
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
            <p>Participante: #{name}</p>
            #{company.present? ? "<p>Empresa: #{company}</p>" : ""}
            <p>Fecha de la Evaluación: #{assessment_date}</p>
          </header>

          <!-- Assessment Data: Questions and Answers -->
          <section id="data">
            <h2>Datos de la Evaluación: Preguntas y Respuestas</h2>
            <dl>
              #{questions_and_answers}
            </dl>
          </section>

          <!-- Diagnostic Results -->
          <section id="insights">
            <h2>Diagnóstico</h2>
            <div class="diagnostic-section">
    HTML

    if diagnostics.any?
      diagnostics.each do |diagnostic|
        html += "<div class=\"diagnostic-item\">#{diagnostic}</div>\n"
      end
    else
      html += "<div class=\"no-diagnostics\">No se activaron diagnósticos específicos basados en tus respuestas.</div>\n"
    end

    html += <<~HTML
            </div>
          </section>

          <!-- Footer -->
          <footer>
            <p>Este reporte se basa en datos auto-reportados y reglas generales; no constituye consejo profesional. Datos de contacto: info@kleer.la</p>
          </footer>
        </div>
      </body>
      </html>
    HTML

    html
  end

  def get_questions_and_answers(contact)
    return '' unless contact.responses.any?

    questions_html = ''
    contact.responses.includes(:question, :answer).each do |response|
      question_text = response.question.name || response.question.text || "Pregunta #{response.question.id}"
      
      answer_text = case response.question.question_type
                   when 'linear_scale', 'radio_button'
                     if response.answer.present?
                       response.answer.text.presence || "Opción #{response.answer.position}"
                     else
                       'Sin respuesta'
                     end
                   when 'short_text', 'long_text'
                     response.text_response.presence || 'Sin respuesta'
                   else
                     'Tipo de pregunta no reconocido'
                   end

      questions_html += "<dt>Pregunta: #{question_text}</dt>\n"
      questions_html += "<dd>Respuesta: #{answer_text}</dd>\n"
    end

    questions_html
  end

  def generate_pdf_from_html(html_content, contact)
    # Using Prawn to generate PDF from HTML-like content
    require 'prawn'

    name = contact.form_data&.dig('name') || 'Participant'
    assessment_title = contact.assessment.title
    diagnostics = contact.assessment.evaluate_rules_for_contact(contact)

    pdf = Prawn::Document.new

    # Register custom fonts to avoid missing font file issues
    if File.exist?(Rails.root.join('vendor/assets/fonts/Raleway-Regular.ttf'))
      pdf.font_families.update(
        'Raleway' => {
          normal: Rails.root.join('vendor/assets/fonts/Raleway-Regular.ttf'),
          regular: Rails.root.join('vendor/assets/fonts/Raleway-Regular.ttf')
        }
      )
    end

    # Use Raleway if available, otherwise use default
    font_name = pdf.font_families['Raleway'] ? 'Raleway' : nil
    pdf.font font_name if font_name

    # Title
    pdf.text assessment_title, size: 24, align: :center
    pdf.move_down 20

    # Participant name
    pdf.text "Participant: #{name}", size: 18, align: :center
    pdf.move_down 30

    # Results section
    pdf.text 'Assessment Results', size: 16
    pdf.move_down 15

    if diagnostics.any?
      diagnostics.each do |diagnostic|
        pdf.text diagnostic, indent_paragraphs: 20
        pdf.move_down 15
      end
    else
      pdf.text 'No specific diagnostics were triggered based on your responses.',
               align: :center
    end

    pdf.render
  end

  def fetch_key_value_from_responses(contact)
    # Initialize a hash for competencies with default value 0
    # competencies = {
    #   'coaching_professional' => 0,
    #   'mentoring' => 0,
    #   'training' => 0,
    #   'lean_agile' => 0,
    #   'facilitacion' => 0,
    #   'maestria_transformacional' => 0,
    #   'maestria_negocios' => 0,
    #   'maestria_tecnica' => 0
    # }

    contact.responses.includes(:question, :answer).reduce({}) do |ac, response|
      question_name = response.question.name.downcase.gsub(/\s+/, '_')

      case response.question.question_type
      when 'linear_scale', 'radio_button'
        if response.answer.present?
          position = (response.answer.position || 0).to_i
          # For radio buttons, position represents the competency level (0-4 scale expected)
          normalized_score = position
          ac.merge(question_name => normalized_score)
        else
          ac # Skip if no answer
        end
      when 'short_text', 'long_text'
        # For text responses, we could analyze sentiment, length, keyword matching, etc.
        # For now, let's assign a placeholder score or skip them from radar charts
        # ac.merge(question_name + '_text' => response.text_response)
        ac # Skip text responses from radar chart for now
      else
        ac # Skip unknown question types
      end
    end
  end
end
