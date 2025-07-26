# frozen_string_literal: true

class EventTypeParticipantsService
  class Result
    attr_reader :success, :message, :data

    def initialize(success:, message: nil, data: {})
      @success = success
      @message = message
      @data = data
    end

    def success?
      @success
    end

    def failure?
      !@success
    end
  end

  def self.participants(event_type)
    new(event_type).participants
  end

  def self.generate_csv(event_type)
    new(event_type).generate_csv
  end

  def initialize(event_type)
    @event_type = event_type
  end

  def participants
    participants = @event_type.events.includes(:participants).flat_map(&:participants)

    success_result(
      data: {
        participants: participants,
        event_type: @event_type,
        total_count: participants.count
      }
    )
  rescue StandardError => e
    failure_result("Error loading participants: #{e.message}")
  end

  def generate_csv
    participants = @event_type.events.includes(:participants).flat_map(&:participants)
    csv_data = Participant.to_csv(participants)
    filename = "participants-#{@event_type.name.parameterize}-#{Date.current.strftime('%Y-%m-%d')}.csv"

    success_result(
      data: {
        csv_data: csv_data,
        filename: filename,
        participants_count: participants.count
      }
    )
  rescue StandardError => e
    failure_result("Error generating CSV: #{e.message}")
  end

  private

  def success_result(message: nil, data: {})
    Result.new(success: true, message: message, data: data)
  end

  def failure_result(message)
    Result.new(success: false, message: message)
  end
end
