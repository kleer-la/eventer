class Assessment < ApplicationRecord
  has_many :question_groups, dependent: :destroy
  has_many :questions, dependent: :destroy
  has_many :contacts, dependent: :destroy

  accepts_nested_attributes_for :question_groups, allow_destroy: true
  accepts_nested_attributes_for :questions, allow_destroy: true

  def self.ransackable_associations(auth_object = nil)
    %w[contacts question_groups questions]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at description id id_value title updated_at]
  end
end
