# frozen_string_literal: true

# A briefing MP3 the connector synthesized, kept only as long as its download
# link lives (#202): the link is the only credential, and the row goes with it.
class HandoffBriefing < ApplicationRecord
  TTL = 1.hour

  belongs_to :handoff_user

  scope :expired, -> { where(expires_at: ..Time.current) }

  def self.purge_expired!
    expired.delete_all
  end

  # Unguessable, self-expiring id for the download URL.
  def download_id
    signed_id(purpose: :download, expires_at: expires_at)
  end

  def expired? = expires_at <= Time.current
end
