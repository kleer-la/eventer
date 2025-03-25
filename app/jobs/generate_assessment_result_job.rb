# app/jobs/generate_assessment_result_job.rb
class GenerateAssessmentResultJob < ActiveJob::Base
  queue_as :default

  def perform(contact_id)
    contact = Contact.find(contact_id)
    contact.update(status: :in_progress)

    # Fetch responses for the contact and map to competencies
    competencies = fetch_key_value_from_responses(contact)
    puts "Competencies: #{competencies}"
    # Generate the radar chart using Gruff
    g = CustomSpider.new(5)
    # g.title = 'Agile Coach Competency Framework Assessment'
    competencies.each do |key, value|
      g.data(key, value)
    end
    g.theme = {
      colors: %w[
        white
        white
        white
        white
        white
        white
        white
      ],
      marker_color: 'pink',
      font_color: 'black',
      background_colors: %w[white white]
    }

    chart_path = Rails.root.join('tmp', "radar_chart_#{contact_id}.png")
    g.write(chart_path)

    # Generate PDF using Prawn
    require 'prawn'
    pdf_file_name = "assessment_#{contact_id}_#{Time.now.strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf_path = Rails.root.join('tmp', pdf_file_name)

    name = contact.form_data&.dig('name') # contact.name
    Prawn::Document.generate(pdf_path) do |pdf|
      pdf.text 'Agile Coach Competency Framework Assessment', size: 24, style: :bold, align: :center
      pdf.text "Name: #{name}", size: 18, align: :center

      # Add the radar chart
      pdf.image chart_path, width: 400, align: :center

      # Add competency levels as a list
      pdf.move_down 20
      pdf.text 'Competency Levels:', size: 16, style: :bold
      competencies.each do |key, value|
        level = case value
                when 0 then 'Novato'
                when 1 then 'Principiante'
                when 2 then 'Intermedio'
                when 3 then 'Avanzado'
                when 4 then 'Experto'
                else 'Novato' # Default
                end
        pdf.text "#{key.to_s.humanize}: #{level}", indent_paragraphs: 20
      end
    end

    store = FileStoreService.current

    public_url = store.upload(pdf_path, pdf_file_name, 'certificate')
    contact.update(assessment_report_url: public_url, status: :completed)
    Log.log(:assessment, :info, "PDF generated for contact #{contact_id}", { public_url: })
  end

  private

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
      position = (response.answer.position || 1).to_i

      # Normalize position (1-5) to 0-4 for the radar chart
      normalized_score = position # - 1

      ac.merge(question_name => normalized_score)
    end
  end
end
