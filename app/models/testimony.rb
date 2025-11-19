# frozen_string_literal: true

class Testimony < ApplicationRecord
  include ImageReference
  references_images_in :photo_url

  # Polymorphic association - can belong to Service or EventType
  belongs_to :testimonial, polymorphic: true

  # Backward compatibility: keep service association for existing queries
  belongs_to :service, optional: true

  has_rich_text :testimony

  # Validations
  validates :first_name, :last_name, presence: true
  validates :testimonial, presence: true

  # Scopes
  scope :starred, -> { where(stared: true) }
  scope :for_event_type, ->(event_type_id) { where(testimonial_type: 'EventType', testimonial_id: event_type_id) }
  scope :for_service, ->(service_id) { where(testimonial_type: 'Service', testimonial_id: service_id) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at first_name id id_value last_name photo_url profile_url service_id stared
       testimonial_id testimonial_type updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[rich_text_testimony service testimonial]
  end

  # Custom ransackers for filtering by polymorphic association
  ransacker :testimonial_of_EventType_type_id do
    Arel.sql("CASE WHEN testimonial_type = 'EventType' THEN testimonial_id END")
  end

  ransacker :testimonial_of_Service_type_id do
    Arel.sql("CASE WHEN testimonial_type = 'Service' THEN testimonial_id END")
  end
end
