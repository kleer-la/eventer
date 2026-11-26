# frozen_string_literal: true

class Country < ApplicationRecord
  has_many :influence_zones

  def to_s
    "#{iso_code} - #{name}"
  end

  # The events admin filters by country (country_id), which searches countries
  # by what names them; none of its associations. ransack 6 needs both said
  # explicitly (#241).
  def self.ransackable_attributes(_auth_object = nil) = %w[iso_code name]
  def self.ransackable_associations(_auth_object = nil) = []
end
