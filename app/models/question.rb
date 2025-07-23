# frozen_string_literal: true

class Question < ApplicationRecord
  belongs_to :assessment
  belongs_to :question_group, optional: true
  has_many :answers, dependent: :destroy
  accepts_nested_attributes_for :answers, allow_destroy: true
  before_validation :set_assessment_from_group, if: :question_group_id?

  enum :question_type, {
    linear_scale: 'linear_scale',
    radio_button: 'radio_button',
    short_text: 'short_text',
    long_text: 'long_text'
  }

  def self.ransackable_attributes(auth_object = nil)
    %w[assessment_id created_at id id_value position question_group_id question_type name description
       updated_at]
  end

  private

  def set_assessment_from_group
    self.assessment ||= question_group.assessment
  end
end
