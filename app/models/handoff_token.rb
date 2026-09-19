# frozen_string_literal: true

# A HandoffUser's personal bearer token for POST /api/tts/briefing (#201). Only
# its SHA-256 digest is stored: the token itself exists in memory right after
# `issue!` and is shown to the person once. One active token per user.
class HandoffToken < ApplicationRecord
  PREFIX = 'kh_'

  belongs_to :handoff_user

  scope :active, -> { where(revoked_at: nil) }

  # The token as issued; only set on the record `issue!` returns.
  attr_reader :plaintext

  def self.issue!(user)
    plaintext = PREFIX + SecureRandom.base58(32)
    transaction do
      user.handoff_tokens.active.find_each(&:revoke!)
      create!(handoff_user: user, digest: digest_of(plaintext)).tap do |token|
        token.instance_variable_set(:@plaintext, plaintext)
      end
    end
  end

  # The active token behind a bearer string, or nil. Records the use.
  def self.authenticate(plaintext)
    return nil if plaintext.blank?

    token = active.find_by(digest: digest_of(plaintext))
    token&.touch(:last_used_at)
    token
  end

  def self.digest_of(plaintext)
    Digest::SHA256.hexdigest(plaintext)
  end

  def revoked? = revoked_at.present?

  def revoke!
    update!(revoked_at: Time.current)
  end
end
