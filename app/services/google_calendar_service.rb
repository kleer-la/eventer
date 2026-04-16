# frozen_string_literal: true

require 'google/apis/calendar_v3'
require 'net/http'
require 'json'

class GoogleCalendarService
  class Result
    attr_reader :success, :message, :data

    def initialize(success:, message: nil, data: {})
      @success = success
      @message = message
      @data = data
    end

    def success? = @success
    def failure? = !@success
  end

  SCOPES = [
    'https://www.googleapis.com/auth/calendar',
    'https://www.googleapis.com/auth/userinfo.email'
  ].freeze

  SLOT_DURATION = 30.minutes
  BUSINESS_START_HOUR = 9
  BUSINESS_END_HOUR = 18
  MAX_DAYS_AHEAD = 14

  def initialize(trainer)
    @trainer = trainer
  end

  def refresh_token_if_needed!
    return success_result if @trainer.google_token_expires_at&.future?

    uri = URI('https://oauth2.googleapis.com/token')
    response = Net::HTTP.post_form(uri, {
      'grant_type' => 'refresh_token',
      'refresh_token' => @trainer.google_refresh_token,
      'client_id' => ENV.fetch('GOOGLE_CLIENT_ID', ''),
      'client_secret' => ENV.fetch('GOOGLE_CLIENT_SECRET', '')
    })

    body = JSON.parse(response.body)
    return failure_result("Token refresh failed: #{body['error']}") unless response.is_a?(Net::HTTPSuccess)

    @trainer.update!(
      google_access_token: body['access_token'],
      google_token_expires_at: Time.current + body['expires_in'].to_i.seconds
    )

    success_result
  rescue StandardError => e
    failure_result("Token refresh error: #{e.message}")
  end

  def fetch_freebusy(start_time, end_time)
    calendar_ids = fetch_calendar_ids
    request_body = {
      timeMin: start_time.iso8601,
      timeMax: end_time.iso8601,
      items: calendar_ids.map { |id| { id: id } }
    }

    uri = URI('https://www.googleapis.com/calendar/v3/freeBusy')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Bearer #{@trainer.google_access_token}"
    req['Content-Type'] = 'application/json'
    req.body = request_body.to_json

    response = http.request(req)
    body = JSON.parse(response.body)

    Rails.logger.info "[GoogleCalendar] FreeBusy queried calendars: #{calendar_ids.inspect}"
    Rails.logger.info "[GoogleCalendar] FreeBusy response keys: #{body['calendars']&.keys&.inspect}"

    # Merge busy periods from all calendars
    all_busy = []
    (body['calendars'] || {}).each_value do |cal_data|
      (cal_data['busy'] || []).each do |period|
        all_busy << { start: Time.parse(period['start']), end: Time.parse(period['end']) }
      end
    end

    Rails.logger.info "[GoogleCalendar] Total busy periods found: #{all_busy.size}"

    success_result(data: { busy_periods: all_busy })
  rescue StandardError => e
    failure_result("FreeBusy error: #{e.message}")
  end

  def create_event(booking)
    event_body = {
      summary: "Consultation with #{booking.visitor_name}",
      description: "Booking via Kleer website\nCompany: #{booking.visitor_company}",
      start: { dateTime: booking.starts_at.iso8601 },
      end: { dateTime: booking.ends_at.iso8601 },
      attendees: [
        { email: booking.visitor_email }
      ],
      conferenceData: {
        createRequest: {
          requestId: SecureRandom.uuid,
          conferenceSolutionKey: { type: 'hangoutsMeet' }
        }
      }
    }

    uri = URI('https://www.googleapis.com/calendar/v3/calendars/primary/events?conferenceDataVersion=1')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Bearer #{@trainer.google_access_token}"
    req['Content-Type'] = 'application/json'
    req.body = event_body.to_json

    response = http.request(req)
    body = JSON.parse(response.body)

    return failure_result("Event creation failed: #{body['error']}") unless response.is_a?(Net::HTTPSuccess)

    success_result(data: {
      google_event_id: body['id'],
      google_meet_link: body['hangoutLink']
    })
  rescue StandardError => e
    failure_result("Event creation error: #{e.message}")
  end

  def compute_available_slots(start_date, end_date, timezone)
    tz = ActiveSupport::TimeZone[timezone] || ActiveSupport::TimeZone['UTC']
    end_date = [end_date, start_date + MAX_DAYS_AHEAD.days].min

    # Generate all candidate 30-min slots on weekdays
    candidates = []
    current_date = start_date
    while current_date <= end_date
      if current_date.on_weekday?
        slot_start = tz.local(current_date.year, current_date.month, current_date.day, BUSINESS_START_HOUR, 0)
        day_end = tz.local(current_date.year, current_date.month, current_date.day, BUSINESS_END_HOUR, 0)

        while slot_start + SLOT_DURATION <= day_end
          candidates << { start: slot_start, end: slot_start + SLOT_DURATION }
          slot_start += SLOT_DURATION
        end
      end
      current_date += 1.day
    end

    return success_result(data: { available_slots: [] }) if candidates.empty?

    # Fetch busy periods for the full range
    range_start = candidates.first[:start]
    range_end = candidates.last[:end]
    freebusy_result = fetch_freebusy(range_start, range_end)
    return freebusy_result if freebusy_result.failure?

    busy_periods = freebusy_result.data[:busy_periods]

    # Filter out slots that overlap with busy periods
    available = candidates.reject do |slot|
      busy_periods.any? { |busy| slot[:start] < busy[:end] && slot[:end] > busy[:start] }
    end

    success_result(data: { available_slots: available })
  rescue StandardError => e
    failure_result("Availability error: #{e.message}")
  end

  private

  def fetch_calendar_ids
    uri = URI('https://www.googleapis.com/calendar/v3/users/me/calendarList')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Bearer #{@trainer.google_access_token}"

    response = http.request(req)
    body = JSON.parse(response.body)

    ids = (body['items'] || []).map { |cal| cal['id'] }
    Rails.logger.info "[GoogleCalendar] CalendarList returned #{ids.size} calendars: #{ids.inspect}"
    ids.presence || ['primary']
  rescue StandardError => e
    Rails.logger.warn "[GoogleCalendar] CalendarList failed (#{e.message}), falling back to primary"
    ['primary']
  end

  def success_result(message: nil, data: {})
    Result.new(success: true, message: message, data: data)
  end

  def failure_result(message)
    Result.new(success: false, message: message)
  end
end
