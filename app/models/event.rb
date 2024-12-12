# frozen_string_literal: true

class Event < ApplicationRecord
  include ActiveSupport

  self.per_page = 20

  belongs_to :country
  belongs_to :trainer
  belongs_to :trainer2, class_name: 'Trainer', foreign_key: 'trainer2_id', optional: true
  belongs_to :trainer3, class_name: 'Trainer', foreign_key: 'trainer3_id', optional: true
  belongs_to :event_type
  has_many :participants
  has_many :categories, through: :event_type

  has_many :campaign_views

  scope :visible, -> { where(cancelled: false).where('date >= ?', DateTime.now - 1) }
  scope :past_visible, -> { where(cancelled: false).where('date <= ?', DateTime.now) }
  scope :public_events, -> { where("visibility_type = 'pu' or visibility_type = 'co'") }
  scope :public_commercial, -> { where(visibility_type: 'pu') }
  scope :public_community_events, -> { where(visibility_type: 'co') }
  scope :public_commercial_visible, -> { visible.public_commercial }
  scope :public_community_visible, -> { visible.public_community_events }
  scope :public_and_visible, -> { visible.public_events }
  scope :public_and_past_visible, -> { past_visible.public_events }
  scope :public_courses, -> { visible.public_commercial.where(draft: false).order('date asc') }

  after_initialize :initialize_defaults

  validates :date, :place, :capacity, :city, :visibility_type, :list_price,
            :country, :trainer, :event_type, :duration, :start_time, :end_time, :address, :mode, presence: true

  validates :capacity, numericality: { greater_than: 0, message: :capacity_should_be_greater_than_0 }
  validates :duration, numericality: { greater_than: 0, message: :duration_should_be_greater_than_0 }
  validates :time_zone_name, presence: true, if: :online?

  validates_each :eb_end_date do |record, attr, value|
    record.errors.add(attr, :eb_end_date_should_be_earlier_than_event_date) unless value.nil? || value < record.date
  end
  validates_each :registration_ends do |record, attr, value|
    unless value.nil? || value <= record.date
      record.errors.add(attr,
                        :registration_ends_should_be_earlier_than_event_date)
    end
  end

  validates_each :eb_price do |record, attr, value|
    unless value.nil? || value < record.list_price
      record.errors.add(attr,
                        :eb_price_should_be_smaller_than_list_price)
    end
  end

  def self.discount_on_private(record, attr, value)
    return unless !value.nil? && (value.positive? && record.visibility_type == 'pr')

    record.errors.add(attr, :private_event_should_not_have_discounts)
  end

  validates_each :couples_eb_price do |record, attr, value|
    discount_on_private(record, attr, value)
  end

  validates_each :business_price do |record, attr, value|
    discount_on_private(record, attr, value)
  end

  validates_each :business_eb_price do |record, attr, value|
    discount_on_private(record, attr, value)
  end

  validates_each :enterprise_6plus_price do |record, attr, value|
    discount_on_private(record, attr, value)
  end

  validates_each :enterprise_11plus_price do |record, attr, value|
    discount_on_private(record, attr, value)
  end

  comma do
    visibility_type 'Visibilidad'
    id 'Event ID'
    event_type('Event Type') { |ev_type| ev_type.nil? ? '' : ev_type.name }
    date 'Fecha de Inicio'
    country('País') { |country| country.nil? ? '' : country.name }
    city 'Ciudad'
    participants 'Registrados', &:count
    participants('Confirmados') { |p| p.count.positive? ? p.confirmed.count : 0 }
    capacity 'Capacidad'
  end

  BANNER_TYPE = {
    info: 'info',
    success: 'success',
    warning: 'warning',
    danger: 'danger'
  }.freeze

  def initialize_defaults
    return unless new_record?

    self.start_time ||= '9:00'
    self.end_time ||= '18:00'
    self.duration ||= 1
    self.should_welcome_email ||= true
  end

  def completion
    return 1.0 if capacity == 0

    stats = participant_statistics
    confirmed = stats[Participant::STATUSES[:confirmed][:code]] || 0
    attended = stats[Participant::STATUSES[:attended][:code]] || 0
    certified = stats[Participant::STATUSES[:certified][:code]] || 0

    total = confirmed + attended + certified
    total.zero? ? 0 : total.to_f / capacity
  end

  def attendance_counts
    con = participants.confirmed.count
    att = participants.attended.count
    cer = participants.certified.count
    { attendance: att + cer, total: con + att + cer }
  end

  def weeks_from(now = Date.today)
    from_date = now.beginning_of_week
    to_date = date.beginning_of_week

    (to_date - from_date) / 7
  end

  def human_date
    start_date = humanize_start_date
    end_date = humanize_date(safe_end_date)

    if event_is_within_the_same_day(start_date, end_date)
      start_date
    elsif event_is_within_the_same_month(start_date, end_date)
      merge_dates_in_same_month(start_date, end_date)
    else
      "#{start_date}-#{end_date}"
    end
  end

  #  {coupons: [{code:nil, percent_off: 20.0}]}
  def coupons
    event_type.active_coupons(Date.today).where(display: true).map do |coupon|
      {
        code: coupon.code,
        percent_off: coupon.percent_off,
        icon: coupon.icon
      }
    end
  end

  def ask_for_coupons_code?
    event_type.active_code_coupons.present?
  end

  def human_long_date
    return "#{human_date} #{date.year}" if date.year == safe_end_date.year

    start_date = humanize_start_date
    end_date = humanize_date(safe_end_date)

    "#{start_date} #{date.year}-#{end_date} #{safe_end_date.year}"
  end

  def human_finish_date
    humanize_date safe_end_date
  end

  def human_time
    from = self.start_time.strftime('%H:%M')
    to = self.end_time.strftime('%H:%M')
    if I18n.locale == :es
      "de #{from} a #{to} hs"
    else
      "from #{from} to #{to} hs"
    end
  end

  def registration_ended?(current_date = Date.today)
    [date, registration_ends].compact.min.to_date <= current_date.to_date
  end

  def finished?
    timezone = TimeZone.new(time_zone_name) unless time_zone_name.nil?

    timezone_current_time = if !timezone.nil?
                              timezone.now
                            else
                              Time.now
                            end

    (Time.parse(self.end_time.strftime('%Y/%m/%d %H:%M')) < timezone_current_time)
  end

  def community_event?
    visibility_type == 'co'
  end

  def classroom?
    mode == 'cl'
  end

  def online?
    mode == 'ol'
  end

  def blended_learning?
    mode == 'bl'
  end

  def trainers
    t = [trainer]
    t <<= trainer2 unless trainer2.nil?
    t <<= trainer3 unless trainer3.nil?
    t
  end

  def name
    event_type.nil? ? '' : event_type.name
  end

  def country_iso
    country.nil? ? '' : country.iso_code
  end

  def country_name
    country.nil? ? '' : country.name
  end

  def unique_name
    "#{name} - #{date.strftime('%Y-%m-%d')} - #{city}, #{country.name}"
  end

  def human_cancellation_limit_date
    humanize_date cancellation_limit_date
  end

  INTERESTED_ERROR = 'No se pudo crear el participante'
  def interested_participant(fname, lname, email, country_iso, notes)
    iz = InfluenceZone.find_by_country(country_iso)
    return "No se encontró el país #{country_iso}. " + INTERESTED_ERROR if iz.nil?

    part = participants.create(status: Participant::STATUS[:new],
                               fname:, lname:, email:,
                               phone: 'na', id_number: 'na', address: 'na', influence_zone: iz,
                               notes:)

    part.save if part.valid?
    part.errors.add(:participants, INTERESTED_ERROR) unless part.valid?
    part.errors.full_messages.join(', ')
  end

  def price(qty, date, referer_code = '')
    discounted_price, _message = event_type.apply_coupons(list_price, qty, date, referer_code)

    if eb_end_date.present? && date.to_date <= eb_end_date.to_date # to_date remove hours
      [earlybird_price(qty), discounted_price].min
    else
      [regular_price(qty), discounted_price].min
    end
  end

  def earlybird_price(qty)
    case qty
    when 0..1
      eb_price || list_price
    when 2..4
      couples_eb_price || eb_price || list_price
    when 5..6
      business_eb_price || couples_eb_price || eb_price || list_price
    else
      enterprise_11plus_price || business_eb_price || couples_eb_price || eb_price || list_price
    end
  end

  def regular_price(qty)
    case qty
    when 0..4
      list_price
    when 5..6
      business_price || list_price
    else
      enterprise_6plus_price || business_price || list_price
    end
  end

  def seat_available
    capacity - confirmed_quantity
  end

  def participant_statistics
    Rails.cache.fetch("#{cache_key_with_version}/participant_statistics") do
      participants.group(:status).sum(:quantity)
    end
  end

  def new_ones_quantity
    participant_statistics[Participant::STATUSES[:new][:code]] || 0
  end

  def contacted_quantity
    participant_statistics[Participant::STATUSES[:contacted][:code]] || 0
  end

  def confirmed_quantity
    participant_statistics[Participant::STATUSES[:confirmed][:code]] || 0
  end

  def attended_quantity
    participant_statistics[Participant::STATUSES[:attended][:code]] || 0
  end

  def certified_quantity
    participant_statistics[Participant::STATUSES[:certified][:code]] || 0
  end

  def experimental_features
    extra_script.to_s.html_safe
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[address average_rating banner_text banner_type business_eb_price business_price
       cancellation_policy cancelled capacity city country_id couples_eb_price created_at currency_iso_code custom_prices_email_text date draft duration eb_end_date eb_price embedded_player enable_online_payment end_time enterprise_11plus_price enterprise_6plus_price event_type_id extra_script finish_date id id_value is_sold_out list_price mailchimp_workflow mailchimp_workflow_call mailchimp_workflow_for_warmup mailchimp_workflow_for_warmup_call mode monitor_email net_promoter_score notify_webinar_start online_cohort_codename online_course_codename place registration_ends registration_link sepyme_enabled should_ask_for_referer_code should_welcome_email show_pricing specific_conditions specific_subtitle start_time time_zone_name trainer2_id trainer3_id trainer_id twitter_embedded_search updated_at visibility_type webinar_started]
  end

  private

  def cancellation_limit_date
    registration_ends.nil? ? date : registration_ends
  end

  def humanize_start_date
    humanize_date date
  end

  def safe_end_date
    if finish_date.nil?
      date + (self.duration || 1) - 1
    else
      finish_date
    end
  end

  def humanize_date(date)
    human_date = I18n.l date, format: :short
    human_date = human_date[-5, 5] if human_date[0] == '0'
    human_date
  end

  def event_is_within_the_same_day(start_date, end_date)
    start_date == end_date
  end

  def event_is_within_the_same_month(start_date, end_date)
    start_date[-3, 3] == end_date[-3, 3]
  end

  def merge_dates_in_same_month(start_date, end_date)
    "#{start_date.split(' ')[0]}-#{end_date.split(' ')[0]} #{start_date[-3, 3]}"
  end
end
