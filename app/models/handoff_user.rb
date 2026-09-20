# frozen_string_literal: true

# Someone using the session-handoff plugin with a personal TTS token (#201).
# Signs in with Google only. Deliberately not a User: any signed-in User reaches
# the ActiveAdmin dashboard, and a HandoffUser must never get near it.
#
# An account is only created for someone who requested the resource on the
# site (the download form of kleer.la/…/session-handoff, which lands here as a
# Contact) with the same email Google vouches for; the request's language
# becomes the account's (#203).
class HandoffUser < ApplicationRecord
  RESOURCE_SLUG = 'session-handoff'
  LOCALES = %w[es en].freeze

  devise :omniauthable, :trackable, omniauth_providers: %i[google_oauth2]

  has_many :handoff_tokens, dependent: :destroy

  validates :email, :google_uid, presence: true
  validates :locale, inclusion: { in: LOCALES }

  # Finds the account for a Google identity, or creates it for a verified email
  # that requested the resource; nil otherwise.
  def self.from_google(auth)
    return nil unless auth.extra&.raw_info&.email_verified

    user = find_by(google_uid: auth.uid) || new_from_request(auth) or return nil
    user.update!(email: auth.info.email, name: auth.info.name)
    user
  end

  def self.new_from_request(auth)
    request = request_for(auth.info.email) or return nil

    new(google_uid: auth.uid, locale: request.form_data['language'].presence_in(LOCALES) || 'es')
  end
  private_class_method :new_from_request

  def self.requested?(email)
    request_for(email).present?
  end

  def self.request_for(email)
    Contact.download_form.where(resource_slug: RESOURCE_SLUG)
           .where('LOWER(email) = ?', email.to_s.strip.downcase).order(:created_at).last
  end

  # Where to request the resource, per language (the site's page for it).
  def self.resource_url(locale)
    site = ENV.fetch('WEBSITE_URL', 'https://www.kleer.la')
    locale.to_s == 'en' ? "#{site}/en/resources/#{RESOURCE_SLUG}" : "#{site}/es/recursos/#{RESOURCE_SLUG}"
  end

  def active_token
    handoff_tokens.active.order(:created_at).last
  end

  def briefings_this_month
    TtsUsage.this_month.where(owner_id: id).count
  end

  def default_voice
    TtsBriefingService::DEFAULT_VOICES.fetch(locale, TtsBriefingService::DEFAULT_VOICE)
  end
end
