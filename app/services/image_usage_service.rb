# app/services/image_usage_service.rb
class ImageUsageService
  class << self
    def register_model(model)
      registered_models << model
    end

    def registered_models
      @registered_models ||= Set.new
    end

    def find_usage(image_url)
      usage = {}

      registered_models.each do |model|
        model_usage = model.where(build_query(model, image_url))
                           .map { |record| record.image_references(image_url) }
                           .flatten

        usage[model.name.underscore.to_sym] = model_usage if model_usage.any?
      end

      usage
    end

    private

    def build_query(model, image_url)
      conditions = []

      # Direct URL matches
      url_conditions = model.image_url_fields.map do |field|
        "#{field} = :url"
      end
      conditions << "(#{url_conditions.join(' OR ')})" if url_conditions.any?

      # Text field contains
      text_conditions = model.image_text_fields.map do |field|
        "#{field} LIKE :pattern"
      end
      conditions << "(#{text_conditions.join(' OR ')})" if text_conditions.any?

      [
        conditions.join(' OR '),
        { url: image_url, pattern: "%#{image_url}%" }
      ]
    end
  end
end
