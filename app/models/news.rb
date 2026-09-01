# frozen_string_literal: true

class News < ApplicationRecord
  include ImageReference
  references_images_in :img, :video, :audio,
                       text_fields: [:description]

  has_and_belongs_to_many :trainers
  enum :lang, %w[es en]

  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }

  after_initialize :set_default_published, if: :new_record?

  private

  def set_default_published
    self.published = false if published.nil?
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[audio created_at description event_date id id_value img lang published title updated_at url
       video where]
  end
end
