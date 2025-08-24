# frozen_string_literal: true

namespace :assessment do
  desc 'Generate assessment HTML for testing purposes'
  task :generate_html, %i[contact_id output_filename] => :environment do |_task, args|
    if args[:contact_id].blank? || args[:output_filename].blank?
      puts 'Usage: rake assessment:generate_html[contact_id,output_filename.html]'
      puts 'Example: rake assessment:generate_html[123,test_report.html]'
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
      output_dir = Rails.root.join('tmp/assessment_html')
      FileUtils.mkdir_p(output_dir)

      output_path = output_dir.join(output_filename)

      # Generate HTML content
      html_content = if assessment.rule_based?
                       generate_rule_based_html(contact)
                     else
                       generate_competency_html(contact)
                     end

      # Save to local file
      File.write(output_path, html_content)

      puts '✅ HTML generated successfully!'
      puts "📄 Saved to: #{output_path}"
      puts "📊 File size: #{File.size(output_path)} bytes"

      # Display some stats
      if contact.responses.any?
        puts "📝 Questions answered: #{contact.responses.count}"

        if assessment.rule_based?
          diagnostics = assessment.evaluate_rules_for_contact(contact)
          puts "🔍 Diagnostics generated: #{diagnostics.count}"
          puts '📋 Diagnostic messages:'
          diagnostics.each_with_index do |diagnostic, index|
            puts "  #{index + 1}. #{diagnostic.truncate(100)}"
          end
        else
          competencies = fetch_competencies_for_contact(contact)
          puts "🎯 Competencies evaluated: #{competencies.count}"
          puts '📊 Competency levels:'
          competencies.each do |key, value|
            next if key.to_s.start_with?('placeholder_')

            level_name = competency_level_name(value)
            puts "  • #{key.humanize}: #{level_name} (#{value})"
          end
        end
      else
        puts '⚠️  No responses found for this contact'
      end

      puts "\n🌐 Open in browser: file://#{output_path}"
    rescue ActiveRecord::RecordNotFound
      puts "❌ Error: Contact with ID #{contact_id} not found"
      exit 1
    rescue StandardError => e
      puts "❌ Error generating HTML: #{e.message}"
      puts e.backtrace.first(5)
      exit 1
    end
  end

  desc 'Create standalone HTML test package for browser testing'
  task :create_test_package, [:contact_id] => :environment do |_task, args|
    contact_id = args[:contact_id] || find_rule_based_contact&.id

    if contact_id.blank?
      puts '❌ No contact specified'
      puts 'Usage: rake assessment:create_test_package[contact_id]'
      puts 'Example: rake assessment:create_test_package[62]'
      exit 1
    end

    contact = Contact.find(contact_id.to_i)
    assessment_type = contact.assessment.rule_based? ? 'rule_based' : 'competency'

    puts "📦 Creating test package for contact #{contact_id} (#{assessment_type})"

    # Create test package directory in writable location
    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    package_name = "assessment_test_#{contact_id}_#{timestamp}"
    package_dir = "/app/tmp/#{package_name}"
    host_package_dir = "/home/juan/dev/eventer/tmp/#{package_name}"

    FileUtils.mkdir_p(package_dir)

    # Generate HTML with relative paths
    # Temporarily override the base URL method to use relative paths
    original_method = AssessmentHtmlGenerator.instance_method(:get_base_url)
    AssessmentHtmlGenerator.define_method(:get_base_url) { '.' }

    begin
      generator = if contact.assessment.rule_based?
                    RuleBasedAssessmentHtmlGenerator.new(contact)
                  else
                    CompetencyAssessmentHtmlGenerator.new(contact)
                  end

      html_content = if contact.assessment.rule_based?
                       generator.generate_html
                     else
                       generator.generate_html_with_chart('./mock_chart.png')
                     end

      # Write HTML file
      html_file = File.join(package_dir, 'assessment_report.html')
      File.write(html_file, html_content)

      # Create images directory and copy images
      images_dir = File.join(package_dir, 'images')
      FileUtils.mkdir_p(images_dir)
      FileUtils.cp('/app/public/images/kleer_compass_header.png', File.join(images_dir, 'kleer_compass_header.png'))
      FileUtils.cp('/app/public/images/kleer_compas_footer.png', File.join(images_dir, 'kleer_compas_footer.png'))

      # Create a mock chart for competency tests
      unless contact.assessment.rule_based?
        File.write(File.join(package_dir, 'mock_chart.png'), 'Mock chart placeholder')
      end

      # Create README
      readme_content = <<~README
        # Assessment Report Test Package

        **Contact ID**: #{contact_id}
        **Assessment**: #{contact.assessment.title}
        **Type**: #{assessment_type}
        **Generated**: #{Time.current}

        ## Files
        - `assessment_report.html` - Main HTML report
        - `images/kleer_compass_header.png` - Header image
        - `images/kleer_compas_footer.png` - Footer image
        #{'- `mock_chart.png` - Mock chart for competency report' unless contact.assessment.rule_based?}

        ## Testing
        1. Open `assessment_report.html` in any web browser
        2. Images should load from the same directory
        3. Report should display with proper styling

        ## Windows WSL Access
        Navigate to: `\\\\wsl$\\Ubuntu\\home\\juan\\dev\\eventer\\tmp\\#{package_name}\\assessment_report.html`

        Or from Windows PowerShell:
        ```
        start \\\\wsl$\\Ubuntu\\home\\juan\\dev\\eventer\\tmp\\#{package_name}\\assessment_report.html
        ```
      README

      File.write(File.join(package_dir, 'README.md'), readme_content)
    ensure
      # Restore original method
      AssessmentHtmlGenerator.define_method(:get_base_url, original_method)
    end

    puts '✅ Test package created successfully!'
    puts "📁 Package location: #{package_dir}"
    puts "📁 Host accessible at: #{host_package_dir}"
    puts '📄 HTML file: assessment_report.html'
    puts '🖼️  Images: images/kleer_compass_header.png, images/kleer_compas_footer.png'
    puts ''
    puts '🌐 Windows browser access:'
    puts "   \\\\wsl$\\Ubuntu\\home\\juan\\dev\\eventer\\tmp\\#{package_name}\\assessment_report.html"
    puts ''
    puts '💡 Or from WSL terminal:'
    puts "   explorer.exe #{host_package_dir}"
  end

  desc 'Test RuleBasedAssessmentHtmlGenerator specifically'
  task :test_rule_based_html, [:contact_id] => :environment do |_task, args|
    contact_id = args[:contact_id] || find_rule_based_contact&.id

    if contact_id.blank?
      puts '❌ No rule-based contact found or specified'
      puts 'Usage: rake assessment:test_rule_based_html[contact_id]'
      puts 'Or use: rake assessment:list_contacts to find rule-based contacts'
      exit 1
    end

    contact_id = contact_id.to_i
    contact = Contact.find(contact_id)

    unless contact.assessment&.rule_based?
      puts "❌ Contact #{contact_id} does not have a rule-based assessment"
      exit 1
    end

    puts '🧪 Testing RuleBasedAssessmentHtmlGenerator'
    puts '=' * 60
    puts "Contact: #{contact.id} - #{contact.form_data&.dig('name') || 'Unknown'}"
    puts "Assessment: #{contact.assessment.title}"

    # Test the generator
    generator = RuleBasedAssessmentHtmlGenerator.new(contact)

    begin
      html_content = generator.generate_html

      # Create test output
      output_dir = Rails.root.join('tmp/assessment_html/tests')
      FileUtils.mkdir_p(output_dir)

      timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
      output_path = output_dir.join("rule_based_test_#{contact_id}_#{timestamp}.html")
      File.write(output_path, html_content)

      puts '✅ RuleBasedAssessmentHtmlGenerator test successful!'
      puts "📄 Output saved to: #{output_path}"
      puts "📊 HTML length: #{html_content.length} characters"

      # Verify key components are present
      checks = [
        { name: 'DOCTYPE declaration', pattern: /<!DOCTYPE html>/ },
        { name: 'Assessment title', pattern: /#{Regexp.escape(contact.assessment.title)}/ },
        { name: 'Participant name', pattern: /#{Regexp.escape(contact.form_data&.dig('name') || 'Participante')}/ },
        { name: 'Questions section', pattern: /id="data"/ },
        { name: 'Diagnostics section', pattern: /id="insights"/ },
        { name: 'Diagnostic styling', pattern: /diagnostic-section/ },
        { name: 'Footer', pattern: /footer-container/ }
      ]

      puts "\n🔍 Content validation:"
      checks.each do |check|
        if html_content.match?(check[:pattern])
          puts "  ✅ #{check[:name]}"
        else
          puts "  ❌ #{check[:name]} - MISSING"
        end
      end

      # Show diagnostics info
      diagnostics = contact.assessment.evaluate_rules_for_contact(contact)
      puts "\n📋 Diagnostics (#{diagnostics.count}):"
      if diagnostics.any?
        diagnostics.each_with_index do |diagnostic, index|
          puts "  #{index + 1}. #{diagnostic.truncate(100)}"
        end
      else
        puts '  (No diagnostics activated for this contact)'
      end

      puts "\n🌐 Open in browser: file://#{output_path}"
    rescue StandardError => e
      puts "❌ RuleBasedAssessmentHtmlGenerator test failed: #{e.message}"
      puts e.backtrace.first(5)
      exit 1
    end
  end

  desc 'Test CompetencyAssessmentHtmlGenerator specifically'
  task :test_competency_html, [:contact_id] => :environment do |_task, args|
    contact_id = args[:contact_id] || find_competency_contact&.id

    if contact_id.blank?
      puts '❌ No competency-based contact found or specified'
      puts 'Usage: rake assessment:test_competency_html[contact_id]'
      puts 'Or use: rake assessment:list_contacts to find competency-based contacts'
      exit 1
    end

    contact_id = contact_id.to_i
    contact = Contact.find(contact_id)

    if contact.assessment&.rule_based?
      puts "❌ Contact #{contact_id} has a rule-based assessment, not competency-based"
      exit 1
    end

    puts '🧪 Testing CompetencyAssessmentHtmlGenerator'
    puts '=' * 60
    puts "Contact: #{contact.id} - #{contact.form_data&.dig('name') || 'Unknown'}"
    puts "Assessment: #{contact.assessment.title}"

    # Test the generator
    generator = CompetencyAssessmentHtmlGenerator.new(contact)

    begin
      # Generate a mock chart URL for testing
      chart_url = "https://example.com/mock_chart_#{contact.id}.png"
      html_content = generator.generate_html_with_chart(chart_url)

      # Create test output
      output_dir = Rails.root.join('tmp/assessment_html/tests')
      FileUtils.mkdir_p(output_dir)

      timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
      output_path = output_dir.join("competency_test_#{contact_id}_#{timestamp}.html")
      File.write(output_path, html_content)

      puts '✅ CompetencyAssessmentHtmlGenerator test successful!'
      puts "📄 Output saved to: #{output_path}"
      puts "📊 HTML length: #{html_content.length} characters"

      # Verify key components are present
      checks = [
        { name: 'DOCTYPE declaration', pattern: /<!DOCTYPE html>/ },
        { name: 'Assessment title', pattern: /Agile Coach Competency Framework/ },
        { name: 'Participant name', pattern: /#{Regexp.escape(contact.form_data&.dig('name') || 'Participante')}/ },
        { name: 'Radar chart section', pattern: /id="chart"/ },
        { name: 'Questions section', pattern: /id="data"/ },
        { name: 'Competency levels section', pattern: /id="levels"/ },
        { name: 'Chart image', pattern: /#{Regexp.escape(chart_url)}/ },
        { name: 'Competency styling', pattern: /competency-levels/ },
        { name: 'Footer', pattern: /footer-container/ }
      ]

      puts "\n🔍 Content validation:"
      checks.each do |check|
        if html_content.match?(check[:pattern])
          puts "  ✅ #{check[:name]}"
        else
          puts "  ❌ #{check[:name]} - MISSING"
        end
      end

      # Show competencies info
      competencies = fetch_competencies_for_contact(contact)
      puts "\n🎯 Competencies (#{competencies.count}):"
      competencies.each do |key, value|
        next if key.to_s.start_with?('placeholder_')

        level_name = competency_level_name(value)
        puts "  • #{key.humanize}: #{level_name} (#{value})"
      end

      puts "\n🌐 Open in browser: file://#{output_path}"
    rescue StandardError => e
      puts "❌ CompetencyAssessmentHtmlGenerator test failed: #{e.message}"
      puts e.backtrace.first(5)
      exit 1
    end
  end

  private

  def generate_rule_based_html(contact)
    generator = RuleBasedAssessmentHtmlGenerator.new(contact)
    generator.generate_html
  end

  def generate_competency_html(contact)
    generator = CompetencyAssessmentHtmlGenerator.new(contact)
    # Generate a placeholder chart URL for testing
    chart_url = "https://example.com/placeholder_chart_#{contact.id}.png"
    generator.generate_html_with_chart(chart_url)
  end

  def find_rule_based_contact
    Contact.joins(:assessment)
           .where(assessments: { rule_based: true })
           .includes(:assessment, :responses)
           .where.not(responses: { id: nil })
           .first
  end

  def find_competency_contact
    Contact.joins(:assessment)
           .where(assessments: { rule_based: false })
           .includes(:assessment, :responses)
           .where.not(responses: { id: nil })
           .first
  end

  def fetch_competencies_for_contact(contact)
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

  def competency_level_name(value)
    case value
    when 0 then 'Novato'
    when 1 then 'Principiante'
    when 2 then 'Intermedio'
    when 3 then 'Avanzado'
    when 4 then 'Experto'
    else 'Novato'
    end
  end
end
