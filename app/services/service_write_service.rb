# frozen_string_literal: true

class ServiceWriteService < ContentWriteService
  self.model = Service
  self.editable_fields = %i[name subtitle slug card_description pricing side_image brochure ordering
                            value_proposition outcomes definitions program target faq
                            seo_title seo_description
                            recommended_way_title recommended_way_note
                            recommended_way_summary recommended_way_details]
  self.rich_text_fields = %i[value_proposition outcomes definitions program target faq]
  self.long_fields = %w[card_description recommended_way_summary recommended_way_details]
  self.publication_flag = :visible
  self.guarded_publication = false

  def initialize(service_area: nil, **args)
    super(**args)
    @service_area = service_area
  end

  private

  def assign
    super
    assign_service_area
  end

  def assign_service_area
    return if @service_area.blank?

    area = ServiceArea.find_by(name: @service_area)
    if area.nil?
      known = ServiceArea.pluck(:name).join(', ')
      return errors << "Unknown service area #{@service_area.inspect}. Existing ones: #{known}"
    end

    @record.service_area = area
  end
end
