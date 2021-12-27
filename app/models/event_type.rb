# frozen_string_literal: true

class EventType < ApplicationRecord
  has_and_belongs_to_many :trainers
  has_and_belongs_to_many :categories
  has_many :events
  has_many :participants, through: :events
  has_many :campaign_views

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

  def testimonies
    part = []
    events.all.each do |e|
      part += e.participants.reject { |p| p.testimony.nil? }
    end
    part
  end
end
