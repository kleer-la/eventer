# frozen_string_literal: true

module Api
  class ContactsController < ApplicationController
    # Skip CSRF if needed
    # skip_before_action :verify_authenticity_token

    def create
      validator = ContactValidator.new(contact_params)

      if validator.valid?
        contact = Contact.new(
          trigger_type: 'contact_form',
          email: contact_params[:email],
          form_data: {
            name: contact_params[:name],
            message: contact_params[:message],
            page: contact_params[:context],
            ip: request.remote_ip,
            user_agent: request.user_agent
          }
        )

        if contact.save
          process_notifications(contact)
          render json: { data: nil }, status: 200
        else
          log_error('Contact save failed', contact.errors.full_messages)
          render json: { error: 'Processing failed' }, status: 422
        end
      else
        log_error('Validation failed', validator.error)
        render json: { error: validator.error }, status: 422
      end
    end

    private

    def contact_params
      params.permit(:name, :email, :context, :subject, :message, :secret)
    end

    def process_notifications(contact)
      templates = MailTemplate.where(
        trigger_type: 'contact_form',
        active: true,
        delivery_schedule: 'immediate'
      )

      templates.each do |template|
        NotificationMailer.custom_notification(contact, template).deliver_later
      end
    end

    def log_error(message, details)
      Log.log(:mail, :info, message, details)
    end
  end
end
