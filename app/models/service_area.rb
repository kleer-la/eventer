# frozen_string_literal: true

class ServiceArea < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  validates_presence_of :name
  has_rich_text :abstract
  enum lang: { sp: 0, en: 1 }

  has_many :services, dependent: :destroy

  def self.ransackable_attributes(auth_object = nil)
    ["abstract", "created_at", "icon", "id", "id_value", "lang", "name", "primary_color", "secondary_color", "slug", "updated_at", "visible"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["rich_text_abstract", "services"]
  end
end
