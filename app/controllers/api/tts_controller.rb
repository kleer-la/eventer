# frozen_string_literal: true

require 'timeout'

module Api
  # Backs the session-handoff Claude Code plugin: turns a briefing (an array of
  # narrated beats) into one MP3, so the plugin needs neither edge-tts nor
  # ffmpeg installed locally. See TtsBriefingService for the synthesis itself.
  #
  # Gated by a single shared secret (TTS_API_SECRET) rather than Doorkeeper —
  # this has nothing to do with a Keventer user account, it is the plugin
  # authenticating to a metered proxy. How that secret reaches an individual
  # plugin user is a separate, undecided product question (see issue #198).
  class TtsController < ApplicationController
    skip_before_action :verify_authenticity_token

    MAX_SYNTHESIS_SECONDS = 60

    before_action :authenticate_tts_request!

    def create
      beats = params.require(:beats).map { |beat| beat.permit(:narration, :duration).to_h }

      mp3 = Timeout.timeout(MAX_SYNTHESIS_SECONDS) do
        TtsBriefingService.call(beats: beats, voice: params[:voice], rate: params[:rate])
      end

      send_data mp3, type: 'audio/mpeg', filename: 'briefing.mp3', disposition: 'attachment'
    rescue ActionController::ParameterMissing, TtsBriefingService::Error => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue Timeout::Error
      render json: { error: 'Synthesis took too long' }, status: :gateway_timeout
    end

    private

    def authenticate_tts_request!
      secret = ENV['TTS_API_SECRET'].to_s
      token = request.headers['Authorization'].to_s.delete_prefix('Bearer ')
      return if secret.present? && ActiveSupport::SecurityUtils.secure_compare(token, secret)

      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
