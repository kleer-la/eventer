# frozen_string_literal: true

# Competency-based assessment PDF generator
# Handles radar chart generation and competency level display
class CompetencyAssessmentPdfGenerator < AssessmentPdfGenerator
  private

  def add_content(pdf)
    # Generate competency report (spider chart version)
    competencies = fetch_key_value_from_responses(@contact)

    # Ensure we have at least 3 data points for the spider chart
    competencies["placeholder_#{competencies.size}"] = 0 while competencies.size < 3 if competencies.size < 3

    # Generate the radar chart
    chart_path = generate_radar_chart(competencies)

    # Add the radar chart to PDF
    pdf.image chart_path, width: 400, align: :center

    # Add competency levels as a list
    add_competency_levels(pdf, competencies)

    # Clean up temporary chart file
    File.delete(chart_path) if File.exist?(chart_path)
  end

  def get_assessment_title
    'Agile Coach Competency Framework Assessment'
  end

  def get_title_size
    24  # Smaller title for competency assessments
  end

  def generate_radar_chart(competencies)
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

    chart_path = Rails.root.join('tmp', "radar_chart_#{@contact.id}.png")
    g.write(chart_path)
    
    chart_path
  end

  def add_competency_levels(pdf, competencies)
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
end