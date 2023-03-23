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
    Event.visible.where(event_type_id: id).order(:date)
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
end
