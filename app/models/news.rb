# frozen_string_literal: true

class News < ApplicationRecord
  include ImageReference
  references_images_in :url,
                       text_fields: [:description]

  has_and_belongs_to_many :trainers
  enum lang: %i[es en]

  def self.ransackable_attributes(auth_object = nil)
    %w[audio created_at description event_date id id_value img lang title updated_at url
       video where]
  end
end
