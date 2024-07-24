class ImageUsageService
  SEARCHABLE_MODELS = [
    [EventType, %i[brochure cover kleer_cert_seal_image side_image], %i[description program recipients faq]],
    [Article, %i[cover], %i[body description]],
    [Resource, %i[cover_es cover_en], %i[getit_es getit_en]],
    [News, %i[url], %i[description]],
    [Participant, %i[photo_url], []],
    [Testimony, %i[photo_url], []],
    [Podcast, %i[thumbnail_url], []],
    [Episode, %i[thumbnail_url], []]
    # Add more models here in the same format: [ModelClass, [url_fields], [text_fields]]
  ]

  def self.find_usage(image_url)
    usage = {}

    SEARCHABLE_MODELS.each do |model_class, url_fields, text_fields|
      model_usage = search_model(image_url, model_class, url_fields, text_fields)
      usage[model_class.name.underscore.to_sym] = model_usage if model_usage.any?
    end

    usage
  end

  def self.search_model(image_url, model_class, url_fields, text_fields)
    usage = []

    # Search in URL fields
    url_fields.each do |field|
      model_class.where(field => image_url).each do |record|
        usage << create_usage_hash(record, field, 'direct')
      end
    end

    # Search in text fields
    text_fields.each do |field|
      model_class.where("#{field} LIKE ?", "%#{image_url}%").each do |record|
        usage << create_usage_hash(record, field, 'embedded')
      end
    end

    usage
  end

  def self.create_usage_hash(record, field, type)
    {
      id: record.id,
      slug: record.respond_to?(:slug) ? record.slug : nil,
      field:,
      type:
    }.compact
  end
end
