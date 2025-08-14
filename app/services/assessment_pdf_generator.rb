# frozen_string_literal: true

# Base PDF generator for assessment reports
# Handles common header, footer, and page structure
# Subclasses override content generation methods
class AssessmentPdfGenerator
  include ApplicationHelper

  def initialize(contact)
    @contact = contact
    @assessment = contact.assessment
  end

  def generate_pdf
    # Set locale for PDF generation
    locale = @assessment.language || @contact.form_data&.dig('language') || 'es'

    I18n.with_locale(locale) do
      create_pdf_document
    end
  end

  private

  def create_pdf_document
    require 'prawn'

    # Create PDF with proper margins for Letter size
    pdf = Prawn::Document.new(page_size: 'LETTER', margin: 40)

    # Setup fonts
    setup_fonts(pdf)

    # Add header with title overlay
    add_header_with_title(pdf)

    # Add participant information
    add_participant_info(pdf)

    # Add main content (implemented by subclasses)
    add_content(pdf)

    # Add footer
    add_footer(pdf)

    pdf.render
  end

  def setup_fonts(pdf)
    # Use Raleway fonts from vendor/assets/fonts
    raleway_regular = Rails.root.join('vendor/assets/fonts/Raleway-Regular.ttf')
    raleway_bold = Rails.root.join('vendor/assets/fonts/Raleway-Bold.ttf')
    raleway_italic = Rails.root.join('vendor/assets/fonts/Raleway-Italic.ttf')

    return unless File.exist?(raleway_regular) && File.exist?(raleway_bold)

    pdf.font_families.update(
      'Raleway' => {
        normal: raleway_regular,
        bold: raleway_bold,
        italic: raleway_italic
      }
    )
    pdf.font 'Raleway'
  end

  def add_header_with_title(pdf)
    # Add header image - full width, no margins, at very top
    header_path = Rails.root.join('app/assets/images/kleer_compass_header.png')
    pdf.image header_path, at: [-40, pdf.bounds.height + 40], width: pdf.bounds.width + 80 if File.exist?(header_path)

    # === ASSESSMENT TITLE OVERLAY ON HEADER ===
    # Position title over the header image - big, white, bold, left aligned
    assessment_title = get_assessment_title

    pdf.fill_color 'FFFFFF'
    pdf.draw_text assessment_title,
                  at: [0, pdf.bounds.height - 45],
                  size: get_title_size,
                  style: :bold
    pdf.fill_color '000000' # Reset to black for other text

    pdf.move_down 120 # Space after header
  end

  def add_participant_info(pdf)
    name = @contact.form_data&.dig('name') || I18n.t('assessment.pdf.participant_default', default: 'Participante')
    company = @contact.form_data&.dig('company')

    # Participant info - compact format like example
    participant_line = "#{I18n.t('assessment.pdf.participant')} #{name}"
    participant_line += "    #{I18n.t('assessment.pdf.company')} #{company}" if company.present?
    pdf.text participant_line, size: 12, align: :center, color: '333333'
    pdf.move_down 8

    # Date with proper locale formatting
    assessment_date_localized = I18n.l(@contact.created_at, format: :long)
    pdf.text "#{I18n.t('assessment.pdf.assessment_date')} #{assessment_date_localized}", size: 12, align: :center,
                                                                                         color: '333333'
    pdf.move_down 40
  end

  def add_footer(pdf)
    pdf.move_down 40

    # === FOOTER TEXT ===
    pdf.text I18n.t('assessment.pdf.footer_disclaimer'),
             size: 9, style: :italic, color: '888888', align: :center

    # Add footer image - full width, positioned so full image is visible
    footer_path = Rails.root.join('app/assets/images/kleer_compas_footer.png')
    return unless File.exist?(footer_path)

    pdf.move_down 10
    # Position footer at height that shows the full image - adjust based on footer image height
    # Try 30 points from bottom - should show full image without being too high
    footer_height = 30
    pdf.image footer_path, at: [-40, footer_height], width: pdf.bounds.width + 80
  end

  # Methods to be overridden by subclasses

  def add_content(pdf)
    raise NotImplementedError, 'Subclasses must implement add_content method'
  end

  def get_assessment_title
    @assessment.title
  end

  def get_title_size
    28 # Default title size, can be overridden
  end

  # Utility methods

  def markdown_to_text(text)
    # Convert markdown to HTML then strip HTML tags for plain text
    return '' if text.nil?

    html = markdown(text)
    ActionView::Base.full_sanitizer.sanitize(html).strip
  end
end
