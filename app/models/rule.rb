# frozen_string_literal: true

class Rule < ApplicationRecord
  belongs_to :assessment

  validates :position, presence: true, uniqueness: { scope: :assessment_id }
  validates :diagnostic_text, presence: true
  validates :conditions, presence: true

  scope :ordered, -> { order(:position) }

  def self.ransackable_attributes(auth_object = nil)
    %w[assessment_id conditions created_at diagnostic_text id position updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    ['assessment']
  end

  # Parse JSON conditions from text field (for SQLite compatibility)
  def parsed_conditions
    @parsed_conditions ||= JSON.parse(conditions)
  rescue JSON::ParserError
    {}
  end

  # Set conditions as JSON (converts hash to JSON string)
  def parsed_conditions=(value)
    self.conditions = value.to_json
    @parsed_conditions = nil
  end

  # Evaluate if this rule matches the given responses
  # conditions format: { question_id => { "value" => X }, question_id => { "range" => [A, B] }, question_id => nil }
  def match?(responses)
    return false if parsed_conditions.empty?

    parsed_conditions.all? do |question_id_str, condition|
      question_id = question_id_str.to_i
      response = responses.find { |r| r.question_id == question_id }

      evaluate_condition(response, condition)
    end
  end

  private

  def evaluate_condition(response, condition)
    # If condition is nil, it means "any value" - always matches if response exists
    return !response.nil? if condition.nil?

    # No response for this question
    return false if response.nil?

    case condition
    when Hash
      evaluate_hash_condition(response, condition)
    else
      false
    end
  end

  def evaluate_hash_condition(response, condition)
    if condition.key?('value')
      # Exact value match
      expected_value = condition['value']
      actual_value = get_response_value(response)
      actual_value == expected_value
    elsif condition.key?('range')
      # Range match (only for numeric values)
      range = condition['range']
      return false unless range.is_a?(Array) && range.size == 2

      actual_value = get_response_value(response)
      return false unless actual_value.is_a?(Numeric)

      min_val, max_val = range
      actual_value >= min_val && actual_value <= max_val
    elsif condition.key?('text_contains')
      # Text contains match (case insensitive)
      search_text = condition['text_contains'].to_s.downcase
      response_text = response.text_response.to_s.downcase
      response_text.include?(search_text)
    else
      false
    end
  end

  def get_response_value(response)
    if response.answer_id.present?
      # For scale/radio questions, use answer position as numeric value
      response.answer&.position
    else
      # For text questions, return the text
      response.text_response
    end
  end
end
