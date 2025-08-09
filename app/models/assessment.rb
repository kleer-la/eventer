# frozen_string_literal: true

class Assessment < ApplicationRecord
  include ImageReference
  references_images_in text_fields: [:description]
  belongs_to :resource, optional: true
  has_many :question_groups, dependent: :destroy
  has_many :questions, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :rules, dependent: :destroy

  accepts_nested_attributes_for :question_groups, allow_destroy: true
  accepts_nested_attributes_for :questions, allow_destroy: true

  validates :language, presence: true, inclusion: { in: %w[en es] }

  def self.ransackable_associations(auth_object = nil)
    %w[resource contacts question_groups questions rules]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at description resource_id id id_value title updated_at language rule_based]
  end

  # Get all responses for a contact in this assessment
  def responses_for_contact(contact)
    contact.responses.joins(:question).where(questions: { assessment_id: id })
  end

  # Evaluate rules for a contact and return matching diagnostics
  def evaluate_rules_for_contact(contact)
    return [] unless rule_based?
    
    responses = responses_for_contact(contact)
    matching_diagnostics = []

    rules.ordered.each do |rule|
      if rule.match?(responses)
        matching_diagnostics << rule.diagnostic_text
      end
    end

    matching_diagnostics
  end
end
