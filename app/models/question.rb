# frozen_string_literal: true

class Question < ApplicationRecord
  belongs_to :assessment
  belongs_to :question_group, optional: true
  has_many :answers, dependent: :destroy

  before_validation :set_assessment_from_group, if: :question_group_id?

  private

  def set_assessment_from_group
    self.assessment ||= question_group.assessment
  end
end
