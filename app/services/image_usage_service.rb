# frozen_string_literal: true

# Where images are used: every model that registers its image fields with
# ImageReference is searched for any of the URLs given, in its URL fields (an
# exact match) and inside its text fields.
class ImageUsageService
  class << self
    def register_model(model)
      registered_models << model
    end

    def registered_models
      @registered_models ||= Set.new
    end

    # `image_urls`: one URL or several ways of writing the same image.
    def find_usage(image_urls)
      urls = Array(image_urls).compact_blank.uniq
      usage = {}

      registered_models.each do |model|
        # Skip models without names (e.g., anonymous test classes)
        next unless model.name.present?

        model_usage = model.where(build_query(model, urls))
                           .flat_map { |record| urls.flat_map { |url| record.image_references(url) } }
                           .uniq

        usage[model.name.underscore.to_sym] = model_usage if model_usage.any?
      end

      usage
    end

    private

    def build_query(model, urls)
      binds = {}
      conditions = urls.each_with_index.flat_map do |url, i|
        binds[:"url#{i}"] = url
        binds[:"pattern#{i}"] = "%#{model.sanitize_sql_like(url)}%"
        model.image_url_fields.map { |field| "#{field} = :url#{i}" } +
          model.image_text_fields.map { |field| "#{field} LIKE :pattern#{i} ESCAPE '\\'" }
      end

      [conditions.join(' OR ').presence || '1 = 0', binds]
    end
  end
end
