# frozen_string_literal: true

# Someone using the session-handoff plugin with a personal TTS token (#201).
# Signs in with Google only. Deliberately not a User: any signed-in User reaches
# the ActiveAdmin dashboard, and a HandoffUser must never get near it.
class HandoffUser < ApplicationRecord
  devise :omniauthable, :trackable, omniauth_providers: %i[google_oauth2]

  has_many :handoff_tokens, dependent: :destroy

  validates :email, :google_uid, presence: true

  # Finds or creates the account for a Google identity; nil unless Google vouches
  # for the email, since the email is all we know the person by.
  def self.from_google(auth)
    return nil unless auth.extra&.raw_info&.email_verified

    user = find_or_initialize_by(google_uid: auth.uid)
    user.update!(email: auth.info.email, name: auth.info.name)
    user
  end

  def active_token
    handoff_tokens.active.order(:created_at).last
  end

  def briefings_this_month
    TtsUsage.this_month.where(owner_id: id).count
  end
end
