# frozen_string_literal: true

class EventType < ApplicationRecord
  include Recommendable
  include ImageReference

  references_images_in :brochure, :cover, :kleer_cert_seal_image, :side_image,
                       text_fields: %i[description program recipients faq]

  belongs_to :canonical, class_name: 'EventType', optional: true
  has_and_belongs_to_many :trainers
  has_and_belongs_to_many :categories
  has_many :events
  has_many :participants, through: :events
  has_many :clons, class_name: 'EventType', foreign_key: 'canonical_id'
  has_and_belongs_to_many :coupons

  # New polymorphic association for Testimony model
  has_many :testimonies, as: :testimonial, dependent: :destroy

  enum :lang, %w[es en]
  enum :platform, { keventer: 0, academia: 1 }

  scope :included_in_catalog, -> { where(include_in_catalog: true, deleted: false) }

  validates :name, :description, :recipients, :program, :trainers, :elevator_pitch, presence: true
  validates :elevator_pitch, length: { maximum: 160,
                                       too_long: '%<count>s characters is the maximum allowed' }
  validate :certification_requires_seal

  def short_name
    if name.length >= 30
      "#{name[0..29]}..."
    else
      name
    end
  end

  def unique_name
    "#{name} (#{tag_name}#{lang}) ##{id}"
  end

  def next_events
    Event.public_courses.where(event_type_id: id).order(:date)
  end

  # Legacy method - returns participant testimonies (text field on participants table)
  # TODO: Deprecate after migration to Testimony model is complete
  def participant_testimonies
    Participant.joins(:event).where(events: { event_type_id: id }).where.not(testimony: '')
               .order(selected: :desc, updated_at: :desc)
  end

  # Returns testimonies for API - combines both new Testimony model and legacy participant testimonies
  # This method maintains backward compatibility during the transition
  def api_testimonies
    # Use new Testimony model if available, otherwise fall back to participant testimonies
    if testimonies.exists?
      # Use stared field for new Testimony model (equivalent to selected)
      testimonies.where(stared: true)
    else
      # Fall back to legacy participant testimonies
      # Note: Not filtering by selected to maintain backward compatibility with existing tests/behavior
      participant_testimonies
    end
  end

  def active_coupons(date)
    coupons.where(active: true).where('expires_on >= ? OR expires_on IS NULL', date)
  end

  def active_codeless_coupons
    active_coupons(Date.today).find_by(coupon_type: :codeless)
  end

  def active_code_coupons
    active_coupons(Date.today).where(coupon_type: :percent_off..:amount_off)
  end

  def apply_coupons(list_price, _qty, date, referer_code)
    ac = active_coupons(date)
    ac = ac.where(code: referer_code.strip.upcase) if referer_code.present?
    ac = ac.where(coupon_type: :codeless) unless referer_code.present?
    return([list_price, '']) if ac == []

    coupon = ac.first
    [(list_price * (100.0 - coupon.percent_off) / 100.0).round(2),
     coupon.internal_name]
  end

  def slug
    "#{id}-#{name.parameterize}"
  end

  def canonical_slug
    if canonical.nil?
      slug
    else
      "#{canonical.id}-#{canonical.name.parameterize}"
    end
  end

  def behavior
    return 'redirect to url' if external_site_url.present?

    if deleted
      return 'redirect to canonical' unless canonical.nil?

      return '404'
    end
    b = 'normal'
    b += ' & canonical' unless canonical.nil?
    b += ' & noindex' if noindex

    b
  end

  def title
    name
  end

  def effective_seo_title
    seo_title.presence || name
  end

  def as_recommendation(lang: 'es')
    super
      .merge('title' => name) # is a method, not an attribute
      .merge('slug' => slug)
      .merge('external_url' => external_site_url)
  end

  accepts_nested_attributes_for :recommended_contents, allow_destroy: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[average_rating brochure cancellation_policy canonical_id cover created_at
       csd_eligible deleted description duration elevator_pitch external_id external_site_url
       extra_script faq goal id id_value include_in_catalog is_kleer_certification kleer_cert_seal_image
       lang learnings materials name net_promoter_score new_version noindex platform program
       promoter_count recipients seo_title side_image subtitle surveyed_count tag_name takeaways updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[canonical categories clons coupons events participants recommended_contents
       recommended_items trainers]
  end

  private

  def certification_requires_seal
    return unless is_kleer_certification && kleer_cert_seal_image.blank?

    errors.add(:kleer_cert_seal_image, 'must be present if this is a Kleer certification')
  end
end
