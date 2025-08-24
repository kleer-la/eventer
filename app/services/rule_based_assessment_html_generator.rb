# frozen_string_literal: true

# HTML generator for rule-based assessment reports
# Includes diagnostic results based on assessment rules
class RuleBasedAssessmentHtmlGenerator < AssessmentHtmlGenerator
  def initialize(contact)
    super(contact)
    @diagnostics = @assessment.evaluate_rules_for_contact(contact)
  end

  private

  def add_content
    add_questions_and_answers_section +
    add_diagnostic_section
  end

  def add_diagnostic_section
    <<~HTML
      <section id="insights">
        <h2>#{I18n.t('assessment.pdf.diagnosis')}</h2>
        <div class="diagnostic-section">
          #{generate_diagnostic_items}
        </div>
      </section>
    HTML
  end

  def generate_diagnostic_items
    if @diagnostics.any?
      diagnostic_html = ''
      @diagnostics.each do |diagnostic|
        diagnostic_html += "<div class=\"diagnostic-item\">#{markdown(diagnostic)}</div>\n"
      end
      diagnostic_html
    else
      "<div class=\"no-diagnostics\">#{I18n.t('no_specific_diagnostics', default: 'No se activaron diagnósticos específicos basados en tus respuestas.')}</div>\n"
    end
  end

  def get_header_color
    '#2D5A5A'
  end

  def get_accent_color
    '#2D5A5A'
  end

  def add_custom_styles
    <<~CSS
      .diagnostic-section {
        background-color: #ffffff;
        padding: 0;
        margin: 0;
      }

      .diagnostic-item {
        margin-bottom: 20px;
        padding: 20px;
        background-color: #ffffff;
        border-left: none;
        border-radius: 0;
        line-height: 1.3;
        color: #333333;
        font-size: 12px;
        box-shadow: none;
      }

      .diagnostic-item p {
        margin: 0 0 12px 0;
        color: #333333;
        font-size: 12px;
        line-height: 1.3;
      }

      .diagnostic-item p:last-child {
        margin-bottom: 0;
      }

      .no-diagnostics {
        text-align: center;
        color: #888888;
        font-style: italic;
        font-size: 12px;
        padding: 40px 20px;
        background-color: #ffffff;
        border-radius: 0;
        margin: 20px 0;
      }
    CSS
  end
end