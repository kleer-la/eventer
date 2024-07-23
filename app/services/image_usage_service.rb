class ImageUsageService
  def self.find_usage(image_url)
    usage = {}

    # Search in EventType
    event_type_usage = search_event_type(image_url)
    usage[:event_type] = event_type_usage if event_type_usage.any?

    # Add more models here as needed

    usage
  end

  private

  def self.search_event_type(image_url)
    usage = []

    # Search in URL fields
    url_fields = %i[brochure cover kleer_cert_seal_image]
    url_fields.each do |field|
      EventType.where(field => image_url).each do |event_type|
        usage << { id: event_type.id, field:, type: 'direct' }
      end
    end

    # Search in text fields
    text_fields = %i[description program]
    text_fields.each do |field|
      EventType.where("#{field} LIKE ?", "%#{image_url}%").each do |event_type|
        usage << { id: event_type.id, field:, type: 'embedded' }
      end
    end
    p usage
    usage
  end
end
