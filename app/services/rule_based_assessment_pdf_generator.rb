# frozen_string_literal: true

# Rule-based assessment PDF generator
# Handles question/answer display and diagnostic results
class RuleBasedAssessmentPdfGenerator < AssessmentPdfGenerator
  private

  def add_content(pdf)
    # Get diagnostics
    diagnostics = @assessment.evaluate_rules_for_contact(@contact)

    # === QUESTIONS AND ANSWERS SECTION ===
    pdf.text I18n.t('assessment.pdf.questions_and_answers'), size: 16, style: :bold, color: '2D5A5A'
    pdf.move_down 20

    add_questions_and_answers(pdf)
    pdf.move_down 25

    # === DIAGNOSTIC RESULTS SECTION ===
    pdf.text I18n.t('assessment.pdf.diagnosis'), size: 16, style: :bold, color: '2D5A5A'
    pdf.move_down 20

    add_diagnostic_results(pdf, diagnostics)
  end

  def add_questions_and_answers(pdf)
    # Add questions and answers with better formatting
    if @contact.responses.any?
      @contact.responses.includes(:question, :answer).each do |response|
        question_text = response.question.name || response.question.text || "#{I18n.t('question',
                                                                                      default: 'Pregunta')} #{response.question.id}"

        # Question text with teal accent (no numbering)
        pdf.text markdown_to_text(question_text), size: 12, style: :bold, color: '2D5A5A'
        pdf.move_down 6

        # Answer text with indentation and styling
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
                        I18n.t('no_response', default: 'Sin respuesta')
                      end

        pdf.text "→ #{markdown_to_text(answer_text)}", size: 11, indent_paragraphs: 15, color: '444444'
        pdf.move_down 15
      end
    else
      pdf.text I18n.t('no_responses_recorded', default: 'No hay respuestas registradas.'),
               size: 11, style: :italic, color: '888888'
    end
  end

  def add_diagnostic_results(pdf, diagnostics)
    if diagnostics.any?
      diagnostics.each do |diagnostic|
        # Add diagnostic text without background separators
        pdf.text markdown_to_text(diagnostic),
                 size: 12, color: '333333', leading: 4
        pdf.move_down 15
      end
    else
      pdf.text I18n.t('no_specific_diagnostics', default: 'No se activaron diagnósticos específicos basados en tus respuestas.'),
               size: 12, style: :italic, align: :center, color: '888888'
    end
  end
end
