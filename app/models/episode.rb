# frozen_string_literal: true

class Episode < ApplicationRecord
  include ImageReference
  references_images_in :thumbnail_url

  belongs_to :podcast
  has_rich_text :description

  validates :title, presence: true
  validates :description, presence: true
  validates :season, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :episode, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :published_at, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at episode id podcast_id published_at season spotify_url thumbnail_url title updated_at youtube_url]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[podcast rich_text_description]
  end

  def description_body
    description.body.to_s
  end
end
