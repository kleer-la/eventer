# frozen_string_literal: true

class EventType < ApplicationRecord
  belongs_to :canonical, class_name: 'EventType', optional: true
  has_and_belongs_to_many :trainers
  has_and_belongs_to_many :categories
  has_many :events
  has_many :participants, through: :events
  has_many :campaign_views
  has_many :clons, class_name: 'EventType', foreign_key: 'canonical_id'
  enum lang: %i[es en]
  enum platform: { keventer: 0, academia: 1 }

  validates :name, :description, :recipients, :program, :trainers, :elevator_pitch, presence: true
  validates :elevator_pitch, length: { maximum: 160,
                                       too_long: '%{count} characters is the maximum allowed' }

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

  def testimonies
    # part = []
    # events.all.each do |e|
    #   part += e.participants.order(selected: :desc, updated_at: :desc).reject { |p| p.testimony.nil? }
    # end
    # part
    Participant.joins(:event).where(events: {event_type_id: id}).where.not(testimony: '').
      order(selected: :desc, updated_at: :desc)
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

  def self.ransackable_attributes(auth_object = nil)
    ["average_rating", "brochure", "cancellation_policy", "canonical_id", "cover", "created_at", 
      "csd_eligible", "deleted", "description", "duration", "elevator_pitch", "external_id", "external_site_url", "extra_script", "faq", "goal", "id", "id_value", "include_in_catalog", "is_kleer_certification", "kleer_cert_seal_image", "lang", "learnings", "materials", "name", "net_promoter_score", "new_version", "noindex", "platform", "program", "promoter_count", "recipients", "side_image", "subtitle", "surveyed_count", "tag_name", "takeaways", "updated_at"]
  end  
end
