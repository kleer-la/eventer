# frozen_string_literal: true

module Api
  class ConsultantsController < Api::V3::BaseController
    # GET /api/service_areas/:slug/consultants
    def index
      service_area = ServiceArea.friendly.find(params[:slug])
      trainers = service_area.trainers.active.booking_enabled

      render json: trainers.as_json(
        only: %i[id name bio bio_en gravatar_email signature_credentials linkedin_url]
      )
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Service area not found' }, status: :not_found
    end

    # GET /api/consultants/:id/availability
    def availability
      trainer = Trainer.active.booking_enabled.find(params[:id])

      unless params[:start].present? && params[:end].present?
        return render json: { error: 'start and end params required' }, status: :bad_request
      end

      start_date = Date.parse(params[:start])
      end_date = Date.parse(params[:end])

      if (end_date - start_date).to_i > GoogleCalendarService::MAX_DAYS_AHEAD
        return render json: { error: "Range cannot exceed #{GoogleCalendarService::MAX_DAYS_AHEAD} days" },
                      status: :unprocessable_entity
      end

      timezone = params[:timezone] || 'America/Argentina/Buenos_Aires'
      service = GoogleCalendarService.new(trainer)
      refresh_result = service.refresh_token_if_needed!
      if refresh_result&.failure?
        return render json: { error: refresh_result.message }, status: :unprocessable_entity
      end

      result = service.compute_available_slots(start_date, end_date, timezone)
      return render(json: { error: result.message }, status: :unprocessable_entity) if result.failure?

      render json: {
        consultant_id: trainer.id,
        timezone: timezone,
        available_slots: result.data[:available_slots].map do |s|
          { start: s[:start].iso8601, end: s[:end].iso8601 }
        end
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Consultant not found' }, status: :not_found
    end

    # POST /api/consultants/:id/bookings
    def create_booking
      local_secret = ENV['CONTACT_US_SECRET'].to_s
      if local_secret.present? && local_secret != params[:secret]
        return render json: { error: 'Authentication failed' }, status: :unprocessable_entity
      end

      trainer = Trainer.active.booking_enabled.find(params[:id])
      service = GoogleCalendarService.new(trainer)
      refresh_result = service.refresh_token_if_needed!
      if refresh_result&.failure?
        return render json: { error: refresh_result.message }, status: :unprocessable_entity
      end

      starts_at = Time.parse(params[:start])
      ends_at = Time.parse(params[:end])

      # Re-check availability via FreeBusy
      freebusy_result = service.fetch_freebusy(starts_at, ends_at)
      if freebusy_result.failure?
        return render json: { error: freebusy_result.message }, status: :unprocessable_entity
      end

      if freebusy_result.data[:busy_periods].any?
        return render json: { error: 'Slot is no longer available' }, status: :unprocessable_entity
      end

      # Create Google Calendar event
      booking = Booking.new(
        trainer: trainer,
        service_area: params[:service_area_slug].present? ? ServiceArea.friendly.find(params[:service_area_slug]) : nil,
        visitor_name: params[:visitor_name],
        visitor_email: params[:visitor_email],
        visitor_company: params[:visitor_company],
        starts_at: starts_at,
        ends_at: ends_at,
        status: 'confirmed',
        notes: params[:notes].presence || params[:visitor_message],
        qualifying_answers: params[:qualifying_answers]
      )

      unless booking.valid?
        return render json: { error: booking.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end

      event_result = service.create_event(booking, context: params[:visitor_context], language: params[:language])
      if event_result.failure?
        return render json: { error: event_result.message }, status: :unprocessable_entity
      end

      booking.google_event_id = event_result.data[:google_event_id]
      booking.save!

      render json: {
        id: booking.id,
        status: booking.status,
        starts_at: booking.starts_at.iso8601,
        ends_at: booking.ends_at.iso8601,
        consultant_name: trainer.name,
        google_meet_link: event_result.data[:google_meet_link]
      }, status: :created
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Consultant not found' }, status: :not_found
    end
  end
end
