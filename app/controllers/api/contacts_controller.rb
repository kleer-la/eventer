# frozen_string_literal: true

module Api
  class ContactsController < ApplicationController
    # Skip CSRF if needed
    skip_before_action :verify_authenticity_token

    def create
      validator = ContactValidator.new(contact_params)

      if validator.valid?
        contact = build_contact

        if contact.save
          process_notifications(contact)
          render json: { data: nil }, status: 200
        else
          log_error('Contact save failed', contact.errors.full_messages)
          render json: { error: 'Processing failed' }, status: 422
        end
      else
        log_error('Validation failed', "#{validator.error} #{contact_params}")
        render json: { error: validator.error }, status: 422
      end
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: 'Resource not found' }, status: 422
    end

    private

    def contact_params
      params.permit(:name, :email, :context, :subject, :message, :secret, :resource_slug)
    end

    def build_contact
      form_data = {
        name: contact_params[:name],
        email: contact_params[:email],
        message: contact_params[:message],
        page: contact_params[:context],
        language: contact_params[:language]
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

      Contact.new(
        trigger_type: determine_trigger_type,
        email: contact_params[:email],
        form_data:
      )
    end

    def determine_trigger_type
      contact_params[:resource_slug].present? ? 'download_form' : 'contact_form'
    end

    def process_notifications(contact)
      templates = MailTemplate.where(
        trigger_type: contact.trigger_type,
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
      Log.log(:mail, :info, message, details)
    end
  end
end
