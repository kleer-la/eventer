# frozen_string_literal: true

require 'timeout'

module Api
  # Backs the session-handoff Claude Code plugin: turns a briefing (an array of
  # narrated beats) into one MP3, so the plugin needs neither edge-tts nor
  # ffmpeg installed locally. See TtsBriefingService for the synthesis itself.
  #
  # Gated by a bearer token rather than Doorkeeper — this has nothing to do with
  # a Keventer user account, it is the plugin authenticating to a metered proxy.
  # The token is either a HandoffUser's personal one (#201, subject to a monthly
  # quota) or the internal shared secret TTS_API_SECRET (no owner, no quota).
  class TtsController < ApplicationController
    skip_before_action :verify_authenticity_token

    MAX_SYNTHESIS_SECONDS = TtsBriefingService::MAX_SYNTHESIS_SECONDS

    before_action :authenticate_tts_request!

    rescue_from TtsUsage::Denied do |e|
      Rails.logger.warn("TTS briefing denied (#{e.status}): #{e.message} — client #{client_hash}, " \
                        "owner #{token_owner&.id || 'internal'}")
      response.set_header('Retry-After', e.retry_after.to_s)
      render json: { error: e.message }, status: e.status
    end
    rescue_from ActionController::ParameterMissing, TtsBriefingService::Error do |e|
      render json: { error: e.message }, status: :unprocessable_content
    end
    rescue_from Timeout::Error do
      render json: { error: 'Synthesis took too long' }, status: :gateway_timeout
    end

    def create
      # Validated before admission: a malformed body is a 422 that spends no quota.
      briefing = briefing_from_params

      @usage = TtsUsage.admit!(beats_count: briefing.beats.size, chars: briefing.narration_chars,
                               client: client_hash, owner: token_owner)
      @started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      mp3 = synthesize(briefing)

      @usage.finish!(:ok, synthesis_ms: elapsed_ms)
      send_data mp3, type: 'audio/mpeg', filename: 'briefing.mp3', disposition: 'attachment'
    ensure
      # Whatever went wrong after admission (422, 504, an unexpected 500), the row
      # must not stay `running`: it would hold a concurrency slot.
      @usage.finish!(:error, synthesis_ms: elapsed_ms) if @usage&.running?
    end

    private

    def client_hash
      TtsUsage.client_hash_for(request.remote_ip)
    end

    # The service enforces its own per-tool deadlines; this is the backstop.
    def synthesize(briefing)
      Timeout.timeout(MAX_SYNTHESIS_SECONDS) do
        TtsBriefingService.call(beats: briefing.beats, voice: params[:voice], rate: params[:rate])
      end
    end

    def briefing_from_params
      TtsBriefingService::Briefing.new(beats: permitted_beats, voice: params[:voice], rate: params[:rate]).validate!
    end

    # Anything that is not a list of objects is passed through as it came, so the
    # briefing rejects it by shape (422) instead of this raising on `permit`.
    def permitted_beats
      beats = params.require(:beats)
      return beats unless beats.is_a?(Array)

      beats.map { |beat| beat.is_a?(ActionController::Parameters) ? beat.permit(:narration, :duration).to_h : beat }
    end

    def elapsed_ms
      return 0 unless @started_at

      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - @started_at) * 1000).round
    end

    def authenticate_tts_request!
      token = request.headers['Authorization'].to_s.delete_prefix('Bearer ')
      return if internal_secret?(token)

      @handoff_token = HandoffToken.authenticate(token)
      return if @handoff_token

      render json: { error: 'Unauthorized' }, status: :unauthorized
    end

    def internal_secret?(token)
      secret = ENV['TTS_API_SECRET'].to_s
      secret.present? && ActiveSupport::SecurityUtils.secure_compare(token, secret)
    end

    def token_owner
      @handoff_token&.handoff_user
    end
  end
end
