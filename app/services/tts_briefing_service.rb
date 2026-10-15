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

  # Wall-clock budget a caller gives one briefing (the controller and the MCP tool both use it).
  MAX_SYNTHESIS_SECONDS = 60
  MAX_BEAT_SECONDS = 60
  BREATH_SECONDS = 0.35
  MAX_BEATS = Briefing::MAX_BEATS
  MAX_TOTAL_CHARS = Briefing::MAX_TOTAL_CHARS
  DEFAULT_VOICES = Briefing::DEFAULT_VOICES
  DEFAULT_VOICE = Briefing::DEFAULT_VOICE
  DEFAULT_RATE = Briefing::DEFAULT_RATE
  # Seconds each tool may run, whatever is left of the overall budget. They run
  # under coreutils `timeout`: a Timeout.timeout around Open3.capture3 does not
  # cut a child that holds the pipes open (measured: a 2 s timeout fired at 6 s).
  TOOL_TIMEOUTS = { 'edge-tts' => 25, 'ffprobe' => 5, 'ffmpeg' => 20 }.freeze
  # After the timeout's TERM, how long before it sends KILL. Reserved out of the budget.
  KILL_GRACE_SECONDS = 2
  TIMEOUT_EXIT_STATUSES = [124, 137].freeze

  def self.call(...) = new(...).call

  def initialize(beats:, voice: nil, rate: nil)
    @briefing = Briefing.new(beats: beats, voice: voice, rate: rate)
  end

  def call
    @briefing.validate!
    @deadline = monotonic_now + MAX_SYNTHESIS_SECONDS

    Dir.mktmpdir('tts-briefing') do |dir|
      segments = @briefing.narrated_beats.each_with_index.map { |beat, index| synthesize_segment(beat, index, dir) }
      concatenate(segments, dir)
    end
  end

  private

  def synthesize_segment(beat, index, dir)
    audio_path = File.join(dir, format('%<i>02d.mp3', i: index))
    # --opt=value, so a narration or rate that starts with a dash is not read as an option.
    run!('edge-tts', "--voice=#{@briefing.voice}", "--rate=#{@briefing.rate}", "--text=#{beat['narration']}",
         '--write-media', audio_path)
    unless File.exist?(audio_path) && File.size(audio_path).positive?
      raise Error, "edge-tts produced no audio for beat #{index + 1}"
    end

    pad_segment(audio_path, floor: duration_floor(beat), dir: dir, index: index)
  end

  def duration_floor(beat)
    seconds = Float(beat['duration'], exception: false)
    seconds&.finite? ? seconds.clamp(0, MAX_BEAT_SECONDS) : 0
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
    Float(stdout.strip)
  rescue ArgumentError, TypeError
    raise Error, 'could not read the audio duration'
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
    tool = args.first
    stdout, stderr, status = Open3.capture3('timeout', '-k', KILL_GRACE_SECONDS.to_s, tool_timeout(tool).to_s, *args)
    return [stdout, stderr] if status.success?

    log_failure(tool, status, stderr)
    raise Error, "#{tool} timed out" if TIMEOUT_EXIT_STATUSES.include?(status.exitstatus)

    raise Error, "#{tool} failed"
  end

  def tool_timeout(tool)
    left = (@deadline - monotonic_now - KILL_GRACE_SECONDS).floor
    raise Error, 'synthesis took too long' if left < 1

    [TOOL_TIMEOUTS.fetch(tool), left].min
  end

  def monotonic_now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  # The tool's stderr stays in the log, never in the response, and without the narration
  # (edge-tts can echo its --text argument).
  def log_failure(tool, status, stderr)
    scrubbed = @briefing.narrated_beats.reduce(stderr.to_s) { |text, beat| text.gsub(beat['narration'], '[narration]') }
    Rails.logger.error("TTS #{tool} failed (exit #{status.exitstatus}): #{scrubbed.truncate(500)}")
  end
end
