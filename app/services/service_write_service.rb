# frozen_string_literal: true

class ServiceWriteService < ContentWriteService
  include OfferingFormatWarnings
  include SlugChangeWarning

  self.model = Service
  self.editable_fields = %i[name subtitle slug card_description pricing side_image hero_image brochure ordering
                            hero_highlight hero_highlight_text
                            value_proposition outcomes definitions program target faq
                            seo_title seo_description
                            recommended_way_title recommended_way_note
                            recommended_way_summary recommended_way_details]
  self.rich_text_fields = %i[value_proposition outcomes definitions program target faq]
  self.long_fields = %w[card_description recommended_way_summary recommended_way_details]
  # Not a content-role model (see Ability::CONTENT_MODELS): whoever may edit a
  # service may publish it.
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

  # Two areas can share a name, one per language, and a service filed under
  # the wrong one shows its hero in the other language. So an ambiguous name is
  # an error, never a guess: the caller retries with the id or the slug.
  def assign_service_area
    return if @service_area.blank?

    areas = ServiceArea.referenced_by(@service_area).order(:lang).to_a
    return errors << unknown_area(areas) if areas.size != 1

    @record.service_area = areas.first
  end

  def unknown_area(areas)
    if areas.empty?
      "Unknown service area #{@service_area.inspect}. Existing ones: #{references(ServiceArea.all)}"
    else
      "Ambiguous service area #{@service_area.inspect}: #{references(areas)}. Pass its id or slug."
    end
  end

  def references(areas) = areas.sort_by { |a| [a.name, a.lang] }.map(&:reference).join('; ')

  def model_warnings
    area = @service_area.present? && @record.service_area ? ["Service area: #{@record.service_area.reference}."] : []
    area + offering_format_warnings + slug_change_warnings + card_warnings
  end

  # website17 shows card_description only when it carries markup: an authored
  # card that replaces the generated one. Plain text — the one-line teaser of
  # the old listing — is ignored, and the service gets the generated card.
  def card_warnings
    card = @fields[:card_description].to_s
    return [] if card.blank? || card.match?(/<[a-z][^>]*>/i)

    ['card_description has no HTML, so the site ignores it and shows the generated card (name, subtitle ' \
     'and a link to the page). Only an authored card in HTML replaces it.']
  end
end
