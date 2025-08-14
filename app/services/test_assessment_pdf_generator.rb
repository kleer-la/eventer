# frozen_string_literal: true

# Test PDF generator for assessment reports without AWS dependencies
# Uses the shared PDF generators for consistent output
class TestAssessmentPdfGenerator
  def initialize(contact)
    @contact = contact
    @assessment = contact.assessment
  end

  def generate_rule_based_pdf
    puts "🔧 Starting rule-based PDF generation for contact #{@contact.id}"
    generator = RuleBasedAssessmentPdfGenerator.new(@contact)
    generator.generate_pdf
  end

  def generate_competency_pdf
    puts "🔧 Starting competency-based PDF generation for contact #{@contact.id}"
    generator = CompetencyAssessmentPdfGenerator.new(@contact)
    generator.generate_pdf
  end
end