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
  validates :released_at, presence: true

  # `released_at` was called `published_at`, and the API still answers with that
  # key: website17 reads it. Remove this and the `methods:` in
  # Api::V3::PodcastsController once the client asks for `released_at`.
  def published_at = released_at

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at episode id podcast_id published released_at season spotify_url thumbnail_url title updated_at
       youtube_url]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[podcast rich_text_description]
  end

  def description_body
    description.body.to_s
  end
end
