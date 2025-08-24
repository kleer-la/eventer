# frozen_string_literal: true

# HTML generator for competency-based assessment reports
# Includes radar chart and competency levels
class CompetencyAssessmentHtmlGenerator < AssessmentHtmlGenerator
  def initialize(contact)
    super(contact)
    @competencies = fetch_competencies
  end

  def generate_html_with_chart(chart_url)
    @chart_url = chart_url
    generate_html
  end

  private

  def add_content
    add_radar_chart_section +
      add_questions_and_answers_section +
      add_competency_levels_section
  end

  def add_radar_chart_section
    return '' unless @chart_url

    <<~HTML
      <section id="chart">
        <h2>#{I18n.t('assessment.competency.radar_chart', default: 'Gráfico de Competencias')}</h2>
        <div class="radar-chart">
          <img src="#{@chart_url}" alt="#{I18n.t('assessment.competency.radar_chart', default: 'Gráfico de Competencias')}"#{' '}
               onerror="this.style.display='none'; this.nextElementSibling.style.display='block';" />
          <div style="display: none; padding: 20px; background-color: #f8f9fa; border: 1px solid #ddd; border-radius: 8px; text-align: center; color: #666;">
            <p>#{I18n.t('assessment.competency.chart_unavailable', default: 'El gráfico de competencias no está disponible en este momento.')}</p>
            <p style="font-size: 0.9em;">#{I18n.t('assessment.competency.see_levels_below', default: 'Los niveles de competencia se muestran a continuación.')}</p>
          </div>
        </div>
      </section>
    HTML
  end

  def add_competency_levels_section
    competency_levels_html = ''
    @competencies.each do |key, value|
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

    <<~HTML
      <section id="levels">
        <h2>#{I18n.t('assessment.competency.levels', default: 'Niveles de Competencia')}</h2>
        <div class="competency-levels">
          <ul>
            #{competency_levels_html}
          </ul>
        </div>
      </section>
    HTML
  end

  def get_assessment_title
    'Agile Coach Competency Framework Assessment'
  end

  def get_header_color
    '#2D5A5A'
  end

  def get_accent_color
    '#2D5A5A'
  end

  def add_custom_styles
    <<~CSS
      .assessment-report ul {
        margin: 10px 0;
        padding-left: 20px;
      }

      .assessment-report li {
        margin-bottom: 8px;
        line-height: 1.4;
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
    CSS
  end

  def fetch_competencies
    @contact.responses.includes(:question, :answer).reduce({}) do |ac, response|
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
end
