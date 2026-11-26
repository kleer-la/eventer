# frozen_string_literal: true

require 'faraday'

module Api
  module V3
    class ParticipantsController < Api::V3::BaseController
      def register
        event = Event.find(params[:event_id])

        # Validate event availability
        return render_error('Event is cancelled or draft', 422) if event.cancelled || event.draft
        return render_error('Registration has ended', 422) if event.registration_ended?
        return render_error('reCAPTCHA configuration missing', 500) unless ENV['RECAPTCHA_SITE_KEY'].present?

        # Create participant
        participant = Participant.new(registration_params)
        participant.event = event

        # Verify reCAPTCHA
        unless verify_recaptcha_for_api(params[:recaptcha_token])
          return render_error('reCAPTCHA verification failed', 422)
        end

        # Use scoped locale instead of global
        I18n.with_locale(event.event_type.lang.to_sym) do
          # Confirm participant if paid event
          participant.confirm! if event.list_price > 0.0

          if participant.save
            # Update status and save
            if event.list_price > 0.0
              participant.contact!
              participant.save
            end

            # Send emails
            send_registration_emails(participant, event)

            # Calculate pricing info for response
            unit_price = participant.applicable_unit_price
            free = unit_price < 0.01

            render json: {
              id: participant.id,
              status: participant.status,
              free: free,
              unit_price: unit_price,
              total_price: unit_price * participant.quantity
            }, status: :created
          else
            render json: {
              errors: participant.errors.full_messages
            }, status: :unprocessable_content
          end
        end
      rescue ActiveRecord::RecordNotFound
        render_error('Event not found', 404)
      rescue StandardError => e
        Rails.logger.error "Registration error: #{e.message}"
        render_error('Registration failed', 500)
      end

      def pricing_info
        event = Event.find(params[:event_id])
        quantity = (params[:quantity] || 1).to_i

        price = event.price(quantity, DateTime.now)
        list_price = event.list_price
        savings = [(list_price - price) * quantity, 0].max

        render json: {
          quantity: quantity,
          unit_price: price,
          total_price: price * quantity,
          list_price: list_price,
          savings: savings,
          currency: event.currency_iso_code || 'USD'
        }
      rescue ActiveRecord::RecordNotFound
        render_error('Event not found', 404)
      end

      private

      def render_error(message, status)
        render json: { error: message }, status: status
      end

      def verify_recaptcha_for_api(token)
        return true if Rails.env.test? # Skip in tests
        return false unless token.present?

        # Use Faraday for reCAPTCHA verification
        conn = Faraday.new(url: 'https://www.google.com/recaptcha/api/')
        response = conn.post('siteverify') do |req|
          req.body = {
            secret: ENV['RECAPTCHA_SECRET_KEY'],
            response: token
          }
        end

        result = JSON.parse(response.body)
        result['success'] == true
      rescue StandardError => e
        Rails.logger.error "reCAPTCHA verification error: #{e.message}"
        false
      end

      def send_registration_emails(participant, event)
        # Same email logic as original controller
        if event.should_welcome_email && event.list_price > 0.0
          invoice = ParticipantInvoiceHelper.new(participant).new_invoice
          EventMailer.delay.welcome_new_event_participant(participant) unless invoice.nil?
        end

        edit_registration_link = "http://eventos.kleer.la/admin/events/#{event.id}/participants/#{participant.id}/edit"

        EventMailer.delay.alert_event_monitor(participant, edit_registration_link)
      end

      def registration_params
        params.permit(
          :fname, :lname, :email, :phone, :company_name, :address,
          :quantity, :referer_code, :notes, :accept_terms
        )
      end
    end
  end
end
