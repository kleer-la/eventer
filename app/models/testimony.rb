# frozen_string_literal: true

class Testimony < ApplicationRecord
  include ImageReference
  references_images_in :photo_url

  belongs_to :service
  has_rich_text :testimony

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at first_name id id_value last_name photo_url profile_url service_id stared
       updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[rich_text_testimony service]
  end
end
