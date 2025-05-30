# frozen_string_literal: true

module Api
  class ContactsController < ApplicationController
    # Skip CSRF if needed
    skip_before_action :verify_authenticity_token
    wrap_parameters false # to avoid nested contact

    def create
      validator = ContactValidator.new(contact_params)
      if validator.valid?
        contact = build_contact
        begin
          ActiveRecord::Base.transaction do
            contact.save!
            process_assessment(contact)
            process_notifications(contact)
          end
          render json: contact.as_json(only: %i[id status assessment_report_url name company]), status: :created
        rescue ActiveRecord::RecordInvalid => e
          log_error('Validation failed during processing', e.message)
          render json: { error: e.message }, status: 422
        rescue StandardError => e
          log_error('Unexpected error', { error: e.message, backtrace: e.backtrace&.first(5) })
          render json: { error: 'Processing failed' }, status: 500
        end
      else
        log_error('Validation failed', "#{validator.error} #{contact_params}")
        render json: { error: validator.error }, status: 422
      end
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: 'Resource not found' }, status: 422
    end

    def status
      contact = Contact.find(params[:contact_id])
      render json: { status: contact.status, assessment_report_url: contact.assessment_report_url }
    end

    def show
      contact = Contact.find(params[:id])
      render json: contact_as_json(contact)
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Contact not found' }, status: 404
    end

    private

    def contact_as_json(contact)
      json = contact.as_json(only: %i[id name email company status assessment_report_url])
      json[:assessment] = assessment_as_json(contact.assessment) if contact.assessment
      json
    end

    def assessment_as_json(assessment)
      assessment.as_json(only: %i[id title description created_at updated_at]).merge(
        questions: assessment.questions.as_json(only: %i[id text]),
        responses: assessment.contacts.find_by(id: params[:id])&.responses&.as_json(only: %i[id question_id answer_id])
      )
    end

    def contact_params
      params.permit(
        :name, :email, :context, :subject, :message, :company, :secret, :language, :resource_slug,
        # New parameter names
        :content_updates_opt_in, :newsletter_opt_in,
        # Old parameter names (for backward compatibility)
        :can_we_contact, :suscribe,
        :initial_slug, :assessment_id, assessment_results: {}
      )
    end

    def boolean_value(param)
      %w[true on 1].include?(param.to_s.downcase)
    end

    def build_contact
      if contact_params[:suscribe] && !contact_params[:newsletter_opt_in]
        Rails.logger.warn("Deprecated param 'suscribe' used")
      end
      if contact_params[:can_we_contact] && !contact_params[:content_updates_opt_in]
        Rails.logger.warn("Deprecated param 'can_we_contact' used")
      end

      form_data = {
        name: contact_params[:name],
        email: contact_params[:email],
        company: contact_params[:company],
        message: contact_params[:message],
        page: contact_params[:context],
        language: contact_params[:language],
        initial_slug: contact_params[:initial_slug],
        content_updates_opt_in: boolean_value(contact_params[:content_updates_opt_in] || contact_params[:can_we_contact]),
        newsletter_opt_in: boolean_value(contact_params[:newsletter_opt_in] || contact_params[:suscribe])
      }

      if contact_params[:resource_slug].present?
        resource = Resource.find_by!(slug: contact_params[:resource_slug])
        form_data.merge!(
          resource_title_es: resource.title_es,
          resource_getit_es: resource.getit_es,
          resource_title_en: resource.title_en,
          resource_getit_en: resource.getit_en,
          resource_slug: resource.slug
        )
      end

      if contact_params[:assessment_id].present?
        form_data[:assessment_id] = contact_params[:assessment_id]
        form_data[:assessment_results] = contact_params[:assessment_results]
      end
      Contact.new(
        trigger_type: determine_trigger_type,
        email: contact_params[:email],
        form_data:,
        assessment_id: contact_params[:assessment_id]
      )
    end

    def determine_trigger_type
      if contact_params[:assessment_id].present? && contact_params[:assessment_results].present?
        'assessment_submission'
      elsif contact_params[:resource_slug].present?
        'download_form'
      else
        'contact_form'
      end
    end

    def process_assessment(contact)
      return unless contact.trigger_type == 'assessment_submission'

      # contact.assessment = Assessment.find(contact.form_data['assessment_id'].to_i)
      assessment_results = contact.form_data['assessment_results']
      ActiveRecord::Base.transaction do
        assessment_results.each do |question_id, answer_id|
          contact.responses.create!(
            question_id:,
            answer_id:
          )
        end
      end
      # GenerateAssessmentResultJob.perform_later(contact.id)
      true
    rescue ActiveRecord::RecordInvalid => e
      log_error('Response creation failed', e.message)
      raise # Re-raise to fail the transaction and signal the controller
    rescue JSON::ParserError => e
      log_error('Invalid assessment_results JSON', e.message)
      raise
    end

    def process_notifications(contact)
      language = (contact.form_data['language'] || 'es').to_sym
      templates = MailTemplate.where(
        trigger_type: contact.trigger_type,
        lang: language,
        active: true,
        delivery_schedule: 'immediate'
      )
      Log.log(:mail, :info, 'Found templates', templates.map(&:identifier))

      templates.each do |template|
        NotificationMailer.custom_notification(contact, template).deliver_later(queue: 'default')
      rescue StandardError => e
        log_error('Notification delivery failed', e.message)
      end
    end

    def log_error(message, details)
      Log.log(:mail, :error, message, details)
    end
  end
end
