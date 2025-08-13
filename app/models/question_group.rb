# frozen_string_literal: true

class QuestionGroup < ApplicationRecord
  include ImageReference
  references_images_in text_fields: [:description]
  belongs_to :assessment
  has_many :questions, -> { order(:position) }, dependent: :destroy
  accepts_nested_attributes_for :questions, allow_destroy: true

  scope :ordered, -> { order(:position) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[assessment_id created_at id id_value name description position updated_at]
  end
end
