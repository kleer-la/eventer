# frozen_string_literal: true

class Role < ApplicationRecord
  has_and_belongs_to_many :users
  # The admin filters use none of its associations; ransack 6 needs that
  # said explicitly (#241).
  def self.ransackable_associations(_auth_object = nil) = []

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id id_value name updated_at]
  end
end
