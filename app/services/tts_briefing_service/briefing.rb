# frozen_string_literal: true

class TtsBriefingService
  # What a caller asked to narrate: validated beats, voice and rate. The service
  # synthesises it and the controller meters it (#narration_chars), so both read
  # the same count.
  class Briefing
    MAX_BEATS = 40
    MAX_TOTAL_CHARS = 6000
    DEFAULT_VOICES = { 'es' => 'es-AR-ElenaNeural', 'en' => 'en-US-JennyNeural' }.freeze
    DEFAULT_VOICE = DEFAULT_VOICES['es']
    DEFAULT_RATE = '+8%'
    VOICE_FORMAT = /\A[a-z]{2}-[A-Z]{2}-[A-Za-z]+\z/
    RATE_FORMAT = /\A[+-]\d{1,3}%\z/

    attr_reader :beats, :voice, :rate

    def initialize(beats:, voice: nil, rate: nil)
      @beats = beats
      @voice = voice.presence || DEFAULT_VOICE
      @rate = rate.presence || DEFAULT_RATE
    end

    # Raises TtsBriefingService::Error unless every field has the right shape.
    def validate!
      validate_beats!
      validate_narration!
      validate_voice_and_rate!
      self
    end

    # Beats that actually get spoken: the blank ones are skipped.
    def narrated_beats
      @narrated_beats ||= beats.select { |beat| beat['narration'].to_s.strip.present? }
    end

    def narration_chars
      narrated_beats.sum { |beat| beat['narration'].length }
    end

    private

    def validate_beats!
      raise Error, 'beats must be a non-empty array' if beats.blank? || !beats.is_a?(Array)
      raise Error, "at most #{MAX_BEATS} beats" if beats.size > MAX_BEATS
      raise Error, 'each beat must be a hash' unless beats.all?(Hash)
      raise Error, 'narration must be a string' unless beats.all? { |beat| narration_shape_ok?(beat) }
    end

    def narration_shape_ok?(beat)
      beat['narration'].nil? || beat['narration'].is_a?(String)
    end

    def validate_narration!
      raise Error, 'no beat has narration' if narrated_beats.empty?
      return if narration_chars <= MAX_TOTAL_CHARS

      raise Error, "narration too long (#{narration_chars} chars, max #{MAX_TOTAL_CHARS})"
    end

    def validate_voice_and_rate!
      raise Error, 'voice must be a string' unless voice.is_a?(String)
      raise Error, 'rate must be a string' unless rate.is_a?(String)
      raise Error, "invalid voice #{voice.inspect}" unless voice.match?(VOICE_FORMAT)
      raise Error, "invalid rate #{rate.inspect}" unless rate.match?(RATE_FORMAT)
    end
  end
end
