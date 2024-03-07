Rails.application.config.to_prepare do
  ActionText::RichText.class_eval do
    def self.ransackable_attributes(auth_object = nil)
      ["body", "created_at", "id", "name", "record_id", "record_type", "updated_at"]
      # Adjust the attributes as needed. Be cautious with sensitive information.
    end
  end
end