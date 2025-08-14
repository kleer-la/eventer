# frozen_string_literal: true

namespace :assessment do
  desc 'Generate assessment PDF for testing purposes'
  task :generate_pdf, %i[contact_id output_filename] => :environment do |_task, args|
    if args[:contact_id].blank? || args[:output_filename].blank?
      puts 'Usage: rake assessment:generate_pdf[contact_id,output_filename.pdf]'
      puts 'Example: rake assessment:generate_pdf[123,test_report.pdf]'
      exit 1
    end

    contact_id = args[:contact_id].to_i
    output_filename = args[:output_filename]

    begin
      contact = Contact.find(contact_id)
      puts "Found contact: #{contact.id} - #{contact.form_data&.dig('name') || 'Unknown'}"

      assessment = contact.assessment
      if assessment.nil?
        puts "Error: Contact #{contact_id} has no associated assessment"
        exit 1
      end

      puts "Assessment: #{assessment.title} (#{assessment.rule_based? ? 'rule-based' : 'competency-based'})"

      # Create output directory if it doesn't exist
      output_dir = Rails.root.join('tmp/assessment_pdfs')
      FileUtils.mkdir_p(output_dir)

      output_path = output_dir.join(output_filename)

      # Generate PDF without AWS dependencies
      generator = TestAssessmentPdfGenerator.new(contact)

      pdf_content = if assessment.rule_based?
                      generator.generate_rule_based_pdf
                    else
                      generator.generate_competency_pdf
                    end

      # Save to local file
      File.binwrite(output_path, pdf_content)

      puts '✅ PDF generated successfully!'
      puts "📄 Saved to: #{output_path}"
      puts "📊 File size: #{File.size(output_path)} bytes"

      # Display some stats
      if contact.responses.any?
        puts "📝 Questions answered: #{contact.responses.count}"

        if assessment.rule_based?
          diagnostics = assessment.evaluate_rules_for_contact(contact)
          puts "🔍 Diagnostics generated: #{diagnostics.count}"
        end
      else
        puts '⚠️  No responses found for this contact'
      end
    rescue ActiveRecord::RecordNotFound
      puts "❌ Error: Contact with ID #{contact_id} not found"
      exit 1
    rescue StandardError => e
      puts "❌ Error generating PDF: #{e.message}"
      puts e.backtrace.first(5)
      exit 1
    end
  end

  desc 'List contacts with assessments for testing'
  task list_contacts: :environment do
    puts 'Contacts with assessments (latest 30):'
    puts '=' * 60

    Contact.joins(:assessment)
           .includes(:assessment, :responses)
           .order(id: :desc)
           .limit(30)
           .each do |contact|
      name = contact.form_data&.dig('name') || 'Unknown'
      company = contact.form_data&.dig('company')
      assessment_type = contact.assessment.rule_based? ? 'rule-based' : 'competency'
      response_count = contact.responses.count

      puts "ID: #{contact.id.to_s.ljust(6)} | #{name.ljust(20)} | #{company&.ljust(15) || 'No company'.ljust(15)} | #{assessment_type.ljust(12)} | #{response_count} responses"
    end

    puts '=' * 60
    puts 'Usage: rake assessment:generate_pdf[CONTACT_ID,filename.pdf]'
  end

  desc 'Generate sample PDFs for multiple contacts'
  task generate_samples: :environment do
    output_dir = Rails.root.join('tmp/assessment_pdfs/samples')
    FileUtils.mkdir_p(output_dir)

    # Get some sample contacts
    rule_based_contacts = Contact.joins(:assessment)
                                 .where(assessments: { rule_based: true })
                                 .includes(:assessment, :responses)
                                 .limit(3)

    competency_contacts = Contact.joins(:assessment)
                                 .where(assessments: { rule_based: false })
                                 .includes(:assessment, :responses)
                                 .limit(3)

    puts 'Generating sample PDFs...'
    puts '=' * 50

    [rule_based_contacts, competency_contacts].flatten.each_with_index do |contact, index|
      next if contact.nil?

      name = contact.form_data&.dig('name')&.parameterize || "contact_#{contact.id}"
      assessment_type = contact.assessment.rule_based? ? 'rule_based' : 'competency'
      filename = "sample_#{index + 1}_#{assessment_type}_#{name}.pdf"

      begin
        generator = TestAssessmentPdfGenerator.new(contact)

        pdf_content = if contact.assessment.rule_based?
                        generator.generate_rule_based_pdf
                      else
                        generator.generate_competency_pdf
                      end

        output_path = output_dir.join(filename)
        File.binwrite(output_path, pdf_content)

        puts "✅ Generated: #{filename} (#{File.size(output_path)} bytes)"
      rescue StandardError => e
        puts "❌ Failed to generate #{filename}: #{e.message}"
      end
    end

    puts '=' * 50
    puts "📁 Sample PDFs saved to: #{output_dir}"
  end
end
