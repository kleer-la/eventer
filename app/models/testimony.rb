# frozen_string_literal: true

class Testimony < ApplicationRecord
  include ImageReference
  references_images_in :photo_url

  # Polymorphic association - can belong to Service or EventType
  belongs_to :testimonial, polymorphic: true

  has_rich_text :testimony

  # Validations
  validates :first_name, :last_name, presence: true
  validates :testimonial, presence: true

  # Scopes
  scope :starred, -> { where(stared: true) }
  scope :for_event_type, ->(event_type_id) { where(testimonial_type: 'EventType', testimonial_id: event_type_id) }
  scope :for_service, ->(service_id) { where(testimonial_type: 'Service', testimonial_id: service_id) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[company created_at first_name id id_value last_name photo_url profile_url role stared
       testimonial_id testimonial_type updated_at]
  end

  # What the site reads: the legacy fname/lname names, plain text, and who speaks.
  def api_json
    { fname: first_name, lname: last_name, role: role, company: company,
      testimony: testimony.to_plain_text, profile_url: profile_url, photo_url: photo_url }
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[rich_text_testimony testimonial]
  end

  # Custom ransackers for filtering by polymorphic association
  ransacker :testimonial_of_EventType_type_id do
    Arel.sql("CASE WHEN testimonial_type = 'EventType' THEN testimonial_id END")
  end

  ransacker :testimonial_of_Service_type_id do
    Arel.sql("CASE WHEN testimonial_type = 'Service' THEN testimonial_id END")
  end
end
