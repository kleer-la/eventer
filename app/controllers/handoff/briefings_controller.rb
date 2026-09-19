# frozen_string_literal: true

module Handoff
  # Serves a briefing MP3 by its signed, expiring id. No session: the person
  # opens the link Claude gave them, possibly in a browser with no login at all.
  class BriefingsController < ApplicationController
    def show
      briefing = HandoffBriefing.find_signed(params[:id], purpose: :download)
      return head :not_found if briefing.nil? || briefing.expired?

      send_data briefing.audio, type: 'audio/mpeg', filename: 'briefing.mp3', disposition: 'attachment'
    end
  end
end
