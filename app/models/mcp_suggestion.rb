# frozen_string_literal: true

class McpSuggestion < ApplicationRecord
  belongs_to :reported_by, class_name: 'User', optional: true

  enum :status, { pending: 0, tracked: 1, done: 2, dismissed: 3 }, default: :pending

  validates_presence_of :friction

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at friction goal id proposal resolution status tools updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[reported_by]
  end
end
