# frozen_string_literal: true

class Podcast < ApplicationRecord
  has_many :episodes, dependent: :destroy
  has_rich_text :description

  accepts_nested_attributes_for :episodes, allow_destroy: true

  validates :title, presence: true
  validates :description, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id spotify_url thumbnail_url title updated_at youtube_url]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[episodes rich_text_description]
  end

  def description_body
    description.body.to_s
  end  
end
