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

    # Generate HTML content using shared generator
    html_generator = RuleBasedAssessmentHtmlGenerator.new(contact)
    html_content = html_generator.generate_html

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

    # Generate HTML content using shared generator
    html_generator = CompetencyAssessmentHtmlGenerator.new(contact)
    html_content = html_generator.generate_html_with_chart(chart_path)

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

end
