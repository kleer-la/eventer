# frozen_string_literal: true

class QuestionGroup < ApplicationRecord
  belongs_to :assessment
  has_many :questions, dependent: :destroy
  accepts_nested_attributes_for :questions, allow_destroy: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[assessment_id created_at id id_value name description position updated_at]
  end
end
