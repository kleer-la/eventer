# frozen_string_literal: true

# One row per POST /api/tts/briefing that reached the guards: what it cost, never
# what it said (#199). It is the source of truth for the overuse limits, so it
# lives in the database — with no Redis and the default cache store, a cache
# counter would not agree between the two web workers.
#
# Limits are read from Setting on every request, so they can be tuned (or the
# endpoint switched off) from the admin without a deploy:
# an unparseable or zero value means the default (see `limits`, shown in the admin):
#   TTS_ENABLED                            'false' / 'off' / 'no' / '0' switches the endpoint off
#   TTS_MAX_BRIEFINGS_PER_HOUR             default 30, across every client
#   TTS_MAX_BRIEFINGS_PER_HOUR_PER_CLIENT  default 10, per client (a hash of the IP)
#   TTS_MAX_CHARS_PER_DAY                  default 60_000
#   TTS_MAX_CONCURRENCY                    default 2
#   TTS_MAX_BRIEFINGS_PER_MONTH_PER_USER   default 30, per HandoffUser (personal tokens only)
class TtsUsage < ApplicationRecord
  # A request the guards turned away: `status` is the HTTP status to answer with.
  class Denied < StandardError
    attr_reader :status, :retry_after

    def initialize(message, status:, retry_after:)
      super(message)
      @status = status
      @retry_after = retry_after
    end
  end

  STATUSES = %w[running ok error].freeze
  OFF_VALUES = %w[false off no 0].freeze
  DEFAULT_MAX_BRIEFINGS_PER_HOUR = 30
  DEFAULT_MAX_BRIEFINGS_PER_HOUR_PER_CLIENT = 10
  DEFAULT_MAX_CHARS_PER_DAY = 60_000
  DEFAULT_MAX_CONCURRENCY = 2
  DEFAULT_MAX_BRIEFINGS_PER_MONTH_PER_USER = 30
  # A synthesis is cut off well before this; a `running` row older than it belongs
  # to a request that died, and must not hold a concurrency slot forever.
  STALE_AFTER = 2.minutes
  CONCURRENCY_RETRY_SECONDS = 5

  validates :status, inclusion: { in: STATUSES }

  # Every status counts against the limits: a failed synthesis still burned CPU.
  scope :within, ->(period) { where(created_at: period.ago..) }
  scope :in_flight, -> { where(status: 'running', created_at: STALE_AFTER.ago..) }
  scope :this_month, -> { where(created_at: Time.current.beginning_of_month..) }

  # Checks the kill switch and the limits, then records the briefing as running.
  # Raises Denied (with the status and Retry-After to answer with) otherwise.
  def self.admit!(beats_count:, chars:, client: nil, owner: nil)
    ensure_enabled!
    ensure_briefings_within_hour!
    ensure_client_within_hour!(client)
    ensure_owner_within_month!(owner)
    ensure_chars_within_day!(chars)

    usage = create!(beats_count: beats_count, chars: chars, client_hash: client, owner_id: owner&.id)
    # Insert first, then count: two simultaneous requests both see each other and
    # both back off, which errs on the side of protecting the public site.
    ensure_concurrency!(usage)
    usage
  end

  def self.ensure_enabled!
    return unless OFF_VALUES.include?(Setting.get('TTS_ENABLED').strip.downcase)

    raise Denied.new('The briefing service is switched off', status: 503, retry_after: 300)
  end

  def self.ensure_briefings_within_hour!
    max = setting_limit('TTS_MAX_BRIEFINGS_PER_HOUR', DEFAULT_MAX_BRIEFINGS_PER_HOUR)
    recent = within(1.hour)
    return if recent.count < max

    raise Denied.new('Hourly briefing limit reached', status: 429, retry_after: seconds_until_room(recent, 1.hour))
  end

  def self.ensure_client_within_hour!(client)
    return if client.blank?

    max = setting_limit('TTS_MAX_BRIEFINGS_PER_HOUR_PER_CLIENT', DEFAULT_MAX_BRIEFINGS_PER_HOUR_PER_CLIENT)
    recent = within(1.hour).where(client_hash: client)
    return if recent.count < max

    raise Denied.new('Hourly briefing limit reached for this client', status: 429,
                                                                      retry_after: seconds_until_room(recent, 1.hour))
  end

  def self.ensure_owner_within_month!(owner)
    return if owner.nil?

    max = setting_limit('TTS_MAX_BRIEFINGS_PER_MONTH_PER_USER', DEFAULT_MAX_BRIEFINGS_PER_MONTH_PER_USER)
    return if this_month.where(owner_id: owner.id).count < max

    next_month = (Time.current.next_month.beginning_of_month - Time.current).ceil
    raise Denied.new('Monthly briefing quota reached', status: 429, retry_after: next_month)
  end

  def self.ensure_chars_within_day!(chars)
    max = setting_limit('TTS_MAX_CHARS_PER_DAY', DEFAULT_MAX_CHARS_PER_DAY)
    recent = within(1.day)
    return if recent.sum(:chars) + chars <= max

    raise Denied.new('Daily narration limit reached', status: 429, retry_after: seconds_until_room(recent, 1.day))
  end

  def self.ensure_concurrency!(usage)
    max = setting_limit('TTS_MAX_CONCURRENCY', DEFAULT_MAX_CONCURRENCY)
    return if in_flight.count <= max

    usage.destroy
    raise Denied.new('Too many briefings in progress', status: 503, retry_after: CONCURRENCY_RETRY_SECONDS)
  end

  # Seconds until the oldest usage in the window ages out (at least 1).
  def self.seconds_until_room(recent, period)
    oldest = recent.minimum(:created_at) or return 1
    [(oldest + period - Time.current).ceil, 1].max
  end

  def self.setting_limit(key, default)
    value = Setting.get(key).to_i
    value.positive? ? value : default
  end

  private_class_method :ensure_enabled!, :ensure_briefings_within_hour!, :ensure_client_within_hour!,
                       :ensure_owner_within_month!, :ensure_chars_within_day!, :ensure_concurrency!,
                       :seconds_until_room, :setting_limit

  # Tells one client from another without keeping the IP: an HMAC keyed with the
  # app secret, so it cannot be brute-forced back from the (small) IPv4 space.
  def self.client_hash_for(ip)
    return nil if ip.blank?

    OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, ip.to_s)[0, 16]
  end

  # The limits as the admin shows them: Setting key, effective value, default.
  def self.limits
    [
      { key: 'TTS_ENABLED', value: Setting.get('TTS_ENABLED').presence || 'true', default: 'true' },
      { key: 'TTS_MAX_BRIEFINGS_PER_HOUR', default: DEFAULT_MAX_BRIEFINGS_PER_HOUR },
      { key: 'TTS_MAX_BRIEFINGS_PER_HOUR_PER_CLIENT', default: DEFAULT_MAX_BRIEFINGS_PER_HOUR_PER_CLIENT },
      { key: 'TTS_MAX_CHARS_PER_DAY', default: DEFAULT_MAX_CHARS_PER_DAY },
      { key: 'TTS_MAX_CONCURRENCY', default: DEFAULT_MAX_CONCURRENCY },
      { key: 'TTS_MAX_BRIEFINGS_PER_MONTH_PER_USER', default: DEFAULT_MAX_BRIEFINGS_PER_MONTH_PER_USER }
    ].map { |l| l.key?(:value) ? l : l.merge(value: setting_limit(l[:key], l[:default])) }
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id status beats_count chars synthesis_ms client_hash owner_id created_at]
  end

  def self.ransackable_associations(_auth_object = nil) = []

  def running? = status == 'running'

  def finish!(status, synthesis_ms:)
    update!(status: status.to_s, synthesis_ms: synthesis_ms)
  end
end
