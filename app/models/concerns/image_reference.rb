# app/models/concerns/image_reference.rb
module ImageReference
  extend ActiveSupport::Concern

  class_methods do
    def references_images_in(*fields, text_fields: [])
      class_attribute :image_url_fields, :image_text_fields

      self.image_url_fields = fields
      self.image_text_fields = text_fields

      # Add the model to searchable models list
      ImageUsageService.register_model(self)
    end
  end

  def image_references(image_url)
    references = []

    # Check URL fields
    self.class.image_url_fields.each do |field|
      next unless self[field] == image_url

      references << {
        id:,
        slug: respond_to?(:slug) ? slug : nil,
        field:,
        type: 'direct'
      }
    end

    # Check text fields
    self.class.image_text_fields.each do |field|
      next unless self[field]&.include?(image_url)

      references << {
        id:,
        slug: respond_to?(:slug) ? slug : nil,
        field:,
        type: 'embedded'
      }
    end

    references
  end
end
