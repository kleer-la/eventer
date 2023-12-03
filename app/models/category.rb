# frozen_string_literal: true

class Category < ApplicationRecord
  has_and_belongs_to_many :event_types

  validates :name, :description, :codename, :tagline, presence: true

  scope :visible_ones, -> { where(visible: true) }
  scope :sorted, -> { order('name DESC') }  # Category.find(:all).sort{|p1,p2| p1.name <=> p2.name}

  def self.ransackable_attributes(auth_object = nil)
    ["codename", "created_at", "description", "description_en", "id", "id_value", "name", "name_en", "order", "tagline", "tagline_en", "updated_at", "visible"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["event_types"]
  end
end
