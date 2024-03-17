# frozen_string_literal: true

class ServiceArea < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  enum lang: { sp: 0, en: 1 }
  has_many :services, dependent: :destroy

  has_rich_text :summary
  has_rich_text :slogan
  has_rich_text :subtitle
  has_rich_text :description
  has_rich_text :target
  has_rich_text :value_proposition

  validates_presence_of %i[
    name summary icon slogan subtitle description side_image target
    primary_color secondary_color side_image
  ]

  def should_generate_new_friendly_id?
    slug.blank?
  end

  def testimonies
    Testimony.joins(:service)
             .where(services: { service_area_id: id })
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[abstract created_at icon id id_value lang name primary_color secondary_color slug updated_at visible]
  end
  def self.ransackable_associations(auth_object = nil)
    %w[services]
  end
end
