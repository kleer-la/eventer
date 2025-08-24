# frozen_string_literal: true

# Base HTML generator for assessment reports
# Handles common header, footer, and page structure
# Subclasses override content generation methods
class AssessmentHtmlGenerator
  include ApplicationHelper

  def initialize(contact)
    @contact = contact
    @assessment = contact.assessment
  end

  def generate_html
    # Set locale for HTML generation
    locale = @assessment.language || @contact.form_data&.dig('language') || 'es'

    I18n.with_locale(locale) do
      create_html_document
    end
  end

  private

  def create_html_document
    build_document_structure do
      add_header +
        '<div class="content-area">' +
        add_content +
        '</div>' +
        add_footer
    end
  end

  def build_document_structure(&block)
    assessment_language = @assessment.language || 'es'
    assessment_title = get_assessment_title

    <<~HTML
      <!DOCTYPE html>
      <html lang="#{assessment_language}">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{assessment_title} - Reporte de Evaluación</title>
        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link href="https://fonts.googleapis.com/css2?family=Raleway:ital,wght@0,400;0,700;1,400&display=swap" rel="stylesheet">
        #{add_styles}
      </head>

      <body>
        <div class="assessment-report">
          #{block.call}
        </div>
      </body>
      </html>
    HTML
  end

  def add_styles
    <<~CSS
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        body {
          font-family: 'Raleway', Arial, sans-serif;
          background-color: #ffffff;
          color: #000000;
          line-height: 1.6;
        }

        .assessment-report {
          width: 100%;
          max-width: none;
          margin: 0;
          min-height: 100vh;
          display: flex;
          flex-direction: column;
        }

        /* Header with image and title overlay */
        .assessment-report .header-container {
          position: relative;
          width: 100%;
          height: 200px;
          margin-bottom: 0;
          overflow: hidden;
        }

        .assessment-report .header-image {
          position: absolute;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          object-fit: cover;
          z-index: 1;
        }

        .assessment-report .header-overlay {
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(0, 0, 0, 0.3);
          display: flex;
          align-items: center;
          padding: 0 40px;
          z-index: 2;
        }

        .assessment-report h1 {
          color: #ffffff;
          font-size: 2.2em;
          font-weight: bold;
          text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
          margin: 0;
          z-index: 2;
        }

        /* Participant info section */
        .assessment-report .participant-info {
          background-color: #ffffff;
          padding: 30px 40px;
          text-align: center;
          margin-bottom: 40px;
        }

        .assessment-report .participant-info p {
          font-size: 12px;
          color: #333333;
          margin: 8px 0;
          display: inline;
          margin-right: 30px;
        }

        .assessment-report .participant-info p:last-child {
          margin-right: 0;
        }

        /* Content area */
        .assessment-report .content-area {
          flex: 1;
          padding: 40px 40px 0 40px;
          background-color: #ffffff;
        }

        .assessment-report section {
          margin-bottom: 40px;
        }

        .assessment-report h2 {
          color: #2D5A5A;
          font-size: 16px;
          font-weight: bold;
          margin-bottom: 20px;
          padding-bottom: 8px;
          border-bottom: 2px solid #2D5A5A;
        }

        .assessment-report p {
          margin: 8px 0;
          line-height: 1.6;
          color: #333333;
        }

        .assessment-report dl {
          margin: 20px 0;
        }

        .assessment-report dt {
          font-weight: bold;
          margin-top: 16px;
          color: #2D5A5A;
          font-size: 12px;
        }

        .assessment-report dd {
          margin-left: 15px;
          margin-bottom: 12px;
          color: #444444;
          font-size: 11px;
          line-height: 1.5;
        }

        /* Footer with background image */
        .assessment-report .footer-container {
          margin-top: auto;
          width: 100%;
          position: relative;
          background-color: #f8f9fa;
          padding: 0;
        }

        .assessment-report .footer-text {
          text-align: center;
          font-size: 9px;
          font-style: italic;
          color: #888888;
          margin-bottom: 20px;
          line-height: 1.4;
          padding: 30px 40px 0 40px;
        }

        .assessment-report .footer-image {
          width: 100%;
          height: auto;
          max-height: 80px;
          object-fit: cover;
          margin: 0;
        }

        .assessment-report img {
          max-width: 100%;
          height: auto;
        }

        /* Print styles */
        @media print {
          .assessment-report {
            min-height: auto;
          }
      #{'    '}
          .header-container {
            height: 150px;
          }
      #{'    '}
          .assessment-report h1 {
            font-size: 1.8em;
          }
      #{'    '}
          .content-area {
            padding: 20px 30px;
          }
      #{'    '}
          .footer-container {
            padding: 0;
          }

          .footer-text {
            padding: 20px 30px 0 30px;
          }
        }

        #{add_custom_styles}
      </style>
    CSS
  end

  def add_header
    name = @contact.form_data&.dig('name') || I18n.t('assessment.pdf.participant_default', default: 'Participante')
    company = @contact.form_data&.dig('company') || ''
    assessment_title = get_assessment_title
    assessment_date = I18n.l(@contact.created_at, format: :long)

    participant_line = "#{I18n.t('assessment.pdf.participant')} #{name}"
    participant_line += "    #{I18n.t('assessment.pdf.company')} #{company}" if company.present?

    header_image_url = get_header_image_url

    <<~HTML
      <div class="header-container">
        #{header_image_url ? "<img src=\"#{header_image_url}\" class=\"header-image\" alt=\"Header\" />" : ''}
        <div class="header-overlay">
          <h1>#{assessment_title}</h1>
        </div>
      </div>
      <div class="participant-info">
        <p>#{participant_line}</p>
        <p>#{I18n.t('assessment.pdf.assessment_date')} #{assessment_date}</p>
      </div>
    HTML
  end

  def add_footer
    footer_image_url = get_footer_image_url

    <<~HTML
      <div class="footer-container">
        <div class="footer-text">
          <p>#{I18n.t('assessment.pdf.footer_disclaimer')}</p>
        </div>
        #{footer_image_url ? "<img src=\"#{footer_image_url}\" class=\"footer-image\" alt=\"Footer\" />" : '<div class="footer-image"></div>'}
      </div>
    HTML
  end

  def add_questions_and_answers_section
    questions_and_answers = get_questions_and_answers

    <<~HTML
      <section id="data">
        <h2>#{I18n.t('assessment.pdf.questions_and_answers')}</h2>
        <dl>
          #{questions_and_answers}
        </dl>
      </section>
    HTML
  end

  def get_questions_and_answers
    return '' unless @contact.responses.any?

    questions_html = ''
    @contact.responses.includes(:question, :answer).each do |response|
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

  # Methods to be overridden by subclasses

  def add_content
    raise NotImplementedError, 'Subclasses must implement add_content method'
  end

  def get_assessment_title
    @assessment.title
  end

  def get_header_color
    '#007BFF' # Default blue, can be overridden
  end

  def get_accent_color
    '#007BFF' # Default blue, can be overridden
  end

  def add_custom_styles
    '' # Override in subclasses for specific styling
  end

  # Utility methods

  def markdown_to_text(text)
    # Convert markdown to HTML then strip HTML tags for plain text
    return '' if text.nil?

    html = markdown(text)
    ActionView::Base.full_sanitizer.sanitize(html).strip
  end

  def get_header_image_url
    public_path = Rails.root.join('public/images/kleer_compass_header.png')
    return nil unless File.exist?(public_path)

    base_url = get_base_url
    "#{base_url}/images/kleer_compass_header.png"
  end

  def get_footer_image_url
    public_path = Rails.root.join('public/images/kleer_compas_footer.png')
    return nil unless File.exist?(public_path)

    base_url = get_base_url
    "#{base_url}/images/kleer_compas_footer.png"
  end

  def get_base_url
    # Use environment-specific base URL
    case Rails.env
    when 'production'
      'https://eventos.kleer.la'
    when 'staging'
      'https://staging.eventos.kleer.la' # adjust as needed
    else
      'http://localhost:3000' # development
    end
  end
end
