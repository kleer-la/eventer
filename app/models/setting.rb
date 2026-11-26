# frozen_string_literal: true

class Setting < ApplicationRecord
  def self.get(key)
    v = Setting.where(key:).first&.value
    v || ''
  end

  # The admin filters use none of its associations; ransack 6 needs that
  # said explicitly (#241).
  def self.ransackable_associations(_auth_object = nil) = []

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id id_value key updated_at value]
  end
end
