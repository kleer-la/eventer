# frozen_string_literal: true

class Role < ApplicationRecord
  has_and_belongs_to_many :users
  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id id_value name updated_at]
  end
end
