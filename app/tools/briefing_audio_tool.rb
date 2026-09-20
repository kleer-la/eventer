# frozen_string_literal: true

require 'timeout'

# The one tool of the session-handoff connector: the briefing in, a download
# link out. A tool result cannot carry an MP3 into the chat, so the audio is kept
# for the hour the link lives (HandoffBriefing) and served by the link alone.
class BriefingAudioTool < HandoffTool
  tool_name 'briefing_audio'

  description <<~MD
    Turns a session-handoff briefing into one narrated MP3 and answers a download
    link that works for one hour, without login. Give the person the link.

    beats are narrated in order; each may set a minimum duration in seconds
    (padded with silence, max 60). At most 40 beats and 6000 characters in all.
    Counts against the person's monthly quota; over it, the answer says when to
    try again.
  MD

  arguments do
    required(:beats).array(:hash) do
      required(:narration).filled(:string).description('What the voice says for this beat')
      optional(:duration).filled(Dry::Types['coercible.float']).description('Minimum seconds this beat lasts, max 60')
    end.description('The briefing, in order')
    optional(:voice).filled(:string).description('edge-tts voice; default follows the account language ' \
                                                 "(#{TtsBriefingService::DEFAULT_VOICES.values.join(' / ')})")
    optional(:rate).filled(:string).description("Speech rate, default #{TtsBriefingService::DEFAULT_RATE}")
  end

  def call(beats:, voice: nil, rate: nil)
    HandoffBriefing.purge_expired!
    beats = beats.map { |beat| beat.to_h.stringify_keys }
    briefing = synthesize(admit(beats), beats: beats, voice: voice.presence || current_handoff_user.default_voice,
                                        rate: rate)
    { download_url: download_url(briefing), expires_at: briefing.expires_at.iso8601,
      note: 'The link works for one hour and needs no login.' }.to_json
  rescue TtsUsage::Denied => e
    error("#{e.message}. Try again in #{ActiveSupport::Duration.build(e.retry_after).inspect}.")
  end

  private

  def admit(beats)
    TtsUsage.admit!(beats_count: beats.size, chars: beats.sum { |beat| beat['narration'].to_s.length },
                    owner: current_handoff_user)
  end

  def synthesize(usage, beats:, voice:, rate:)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    mp3 = Timeout.timeout(TtsBriefingService::MAX_SYNTHESIS_SECONDS) do
      TtsBriefingService.call(beats: beats, voice: voice, rate: rate)
    end
    usage.finish!(:ok, synthesis_ms: elapsed_ms(started))
    HandoffBriefing.create!(handoff_user: current_handoff_user, audio: mp3, beats_count: beats.size,
                            expires_at: HandoffBriefing::TTL.from_now)
  rescue TtsBriefingService::Error, Timeout::Error => e
    usage.finish!(:error, synthesis_ms: elapsed_ms(started))
    raise Denied, (e.is_a?(Timeout::Error) ? 'Synthesis took too long' : e.message)
  end

  # Rides the Denied rescue in `call`: a synthesis failure is reported the same way.
  class Denied < TtsUsage::Denied
    def initialize(message)
      super(message, status: 422, retry_after: 0)
    end
  end

  def download_url(briefing)
    scheme = headers['x-forwarded-proto'].presence || (Rails.env.production? ? 'https' : 'http')
    "#{scheme}://#{headers['host']}/handoff/briefings/#{briefing.download_id}"
  end

  def elapsed_ms(started)
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
  end
end
