# frozen_string_literal: true

require 'open3'
require 'tmpdir'

# Turns a session-handoff briefing (an array of beats, each carrying `narration`
# and an optional `duration` floor) into one narrated MP3 — the same job
# plugins/session-handoff/skills/session-handoff/engine/make_brief.sh does
# locally with edge-tts + ffmpeg, run here instead so the plugin needs neither.
#
# Each beat is synthesised on its own, padded with ffmpeg so it lasts at least
# its `duration` floor (plus a 0.35s breath so sentences do not run together),
# then all beats are concatenated into a single MP3.
class TtsBriefingService
  Error = Class.new(StandardError)

  MAX_BEATS = 40
  MAX_TOTAL_CHARS = 6000
  BREATH_SECONDS = 0.35
  DEFAULT_VOICE = 'es-AR-ElenaNeural'
  DEFAULT_RATE = '+8%'
  VOICE_FORMAT = /\A[a-z]{2}-[A-Z]{2}-[A-Za-z]+\z/

  def self.call(...) = new(...).call

  def initialize(beats:, voice: nil, rate: nil)
    @beats = beats
    @voice = voice.presence || DEFAULT_VOICE
    @rate = rate.presence || DEFAULT_RATE
  end

  def call
    validate!

    Dir.mktmpdir('tts-briefing') do |dir|
      segments = narrated_beats.each_with_index.map { |beat, index| synthesize_segment(beat, index, dir) }
      concatenate(segments, dir)
    end
  end

  private

  def narrated_beats
    @narrated_beats ||= @beats.select { |beat| beat['narration'].to_s.strip.present? }
  end

  def validate!
    validate_beats!
    validate_narration!
    raise Error, "invalid voice #{@voice.inspect}" unless @voice.match?(VOICE_FORMAT)
  end

  def validate_beats!
    raise Error, 'beats must be a non-empty array' if @beats.blank? || !@beats.is_a?(Array)
    raise Error, "at most #{MAX_BEATS} beats" if @beats.size > MAX_BEATS
  end

  def validate_narration!
    raise Error, 'no beat has narration' if narrated_beats.empty?

    total_chars = narrated_beats.sum { |beat| beat['narration'].to_s.length }
    raise Error, "narration too long (#{total_chars} chars, max #{MAX_TOTAL_CHARS})" if total_chars > MAX_TOTAL_CHARS
  end

  def synthesize_segment(beat, index, dir)
    audio_path = File.join(dir, format('%<i>02d.mp3', i: index))
    run!('edge-tts', '--voice', @voice, '--rate', @rate, '--text', beat['narration'].to_s,
         '--write-media', audio_path)
    unless File.exist?(audio_path) && File.size(audio_path).positive?
      raise Error, "edge-tts produced no audio for beat #{index + 1}"
    end

    pad_segment(audio_path, floor: beat['duration'].to_f, dir: dir, index: index)
  end

  def pad_segment(audio_path, floor:, dir:, index:)
    duration = audio_duration(audio_path)
    segment_duration = [duration + BREATH_SECONDS, floor].max
    pad = [0.0, segment_duration - duration].max

    padded_path = File.join(dir, format('%<i>02d_padded.mp3', i: index))
    run!('ffmpeg', '-y', '-i', audio_path, '-af', "apad=pad_dur=#{pad}", '-c:a', 'libmp3lame', '-q:a', '4',
         padded_path)
    padded_path
  end

  def audio_duration(path)
    stdout, = run!('ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', path)
    Float(stdout)
  end

  def concatenate(segments, dir)
    concat_file = File.join(dir, 'concat.txt')
    File.write(concat_file, segments.map { |segment| "file '#{segment}'\n" }.join)

    output_path = File.join(dir, 'briefing.mp3')
    run!('ffmpeg', '-y', '-f', 'concat', '-safe', '0', '-i', concat_file, '-c:a', 'libmp3lame', '-q:a', '4',
         output_path)
    File.binread(output_path)
  end

  def run!(*args)
    stdout, stderr, status = Open3.capture3(*args)
    raise Error, "#{args.first} failed: #{stderr.presence || stdout}" unless status.success?

    [stdout, stderr]
  end
end
