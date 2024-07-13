# frozen_string_literal: true

Rails.application.config.to_prepare do
  ActionText::RichText.class_eval do
    def self.ransackable_attributes(_auth_object = nil)
      %w[body created_at id name record_id record_type updated_at]
      # Adjust the attributes as needed. Be cautious with sensitive information.
    end
  end
end
