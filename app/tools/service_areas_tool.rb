# frozen_string_literal: true

# Service areas — the group a Service belongs to, with a page of its own: one
# tool, four operations. The page blocks are rich text (HTML).
class ServiceAreasTool < AuthenticatedTool
  tool_name 'service_areas'
  requires_permission :read, ServiceArea

  OPERATIONS = %w[list get create update].freeze
  BLOCKS = %i[summary cta_message slogan subtitle description target value_proposition].freeze

  description <<~MD
    Service areas: the group a Service belongs to, each with its own page
    (summary, slogan, subtitle, description, target, value proposition, CTA
    message), palette and icon.

    operation=list (default): summaries in display order, filtered by query
    (name), visible. Long texts are not included.
    operation=get: one area in full, by id (slug or numeric): the rich-text
    blocks, palette and icon, the recommended-way copy, and the services
    listed under it.
    operation=create: needs name, summary, icon, slogan, subtitle, description,
    side_image, primary_color, secondary_color, cta_message, seo_title and
    seo_description; hidden unless visible=true.
    operation=update: edits area `id`; only the fields passed are touched. A
    block passed whole replaces the whole block — read it first. To change
    part of one, prefer `replacements`, matched against that HTML (it patches
    the blocks, recommended_way_summary and _details).

    Writes take two steps: confirm=false (the default) previews without saving.
  MD

  arguments do
    optional(:operation).filled(:string).description("'list' (default), 'get', 'create' or 'update'")
    optional(:id).filled(:string).description('get/update: service area slug (preferred) or numeric id')
    optional(:query).filled(:string).description('list: substring matched against the name')
    optional(:visible).filled(:bool).description('list: filter. create/update: shown on the site or not')
    optional(:limit).filled(:integer).description("list: how many (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
    optional(:name).filled(:string).description('Service area name')
    optional(:slug).filled(:string).description('URL slug; derived from the name when omitted')
    optional(:lang).filled(:string).description("Language: 'es' or 'en'")
    optional(:icon).filled(:string).description('Icon image URL')
    optional(:side_image).filled(:string).description('Side image URL')
    optional(:primary_color).filled(:string).description('Primary color, e.g. "#68CEF2"')
    optional(:secondary_color).filled(:string).description('Secondary color, e.g. "#68CEF2"')
    optional(:primary_font_color).filled(:string).description('Primary button text color')
    optional(:secondary_font_color).filled(:string).description('Secondary button text color')
    optional(:summary).filled(:string).description('Summary block; HTML accepted')
    optional(:cta_message).filled(:string).description('Shown just before the buttons; HTML accepted')
    optional(:slogan).filled(:string).description('Slogan block; HTML accepted')
    optional(:subtitle).filled(:string).description('Subtitle block; HTML accepted')
    optional(:description).filled(:string).description('Description block; HTML accepted')
    optional(:target_title).filled(:string).description('Optional title for the target section')
    optional(:target).filled(:string).description('Who it is for; HTML accepted')
    optional(:value_proposition_title).filled(:string)
                                      .description('Optional title for the value proposition section')
    optional(:value_proposition).filled(:string).description('Value proposition block; HTML accepted')
    optional(:ordering).filled(:integer).description('Display order')
    optional(:is_training_program).filled(:bool).description('true = it is a training program area')
    optional(:seo_title).filled(:string).description('SEO title')
    optional(:seo_description).filled(:string).description('SEO description')
    optional(:recommended_way_title).filled(:string).description('Recommended-way title')
    optional(:recommended_way_note).filled(:string).description('Recommended-way note')
    optional(:recommended_way_summary).filled(:string).description('Recommended-way summary')
    optional(:recommended_way_details).filled(:string).description('Recommended-way details')
    optional(:confirm).filled(:bool).description('create/update: false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  def call(operation: 'list', id: nil, confirm: false, limit: DEFAULT_LIMIT, visible: nil, **fields)
    case operation
    when 'list' then list(limit: limit, visible: visible, query: fields[:query])
    when 'get' then get(find(id))
    when 'create' then write(nil, confirm: confirm, visible: visible || false, **fields.except(:query))
    when 'update' then write(find(id), confirm: confirm, visible: visible, **fields.except(:query))
    else unknown_operation(operation)
    end
  rescue ActiveRecord::RecordNotFound
    error("No service area with slug or id #{id.inspect}")
  end

  private

  def find(id)
    raise ActiveRecord::RecordNotFound if id.blank?

    ServiceArea.friendly.find(id)
  end

  def list(limit:, query: nil, visible: nil)
    scope = ServiceArea.order(:ordering, :name)
    scope = scope.where('name LIKE ?', "%#{query}%") if query.present?
    scope = scope.where(visible: visible) unless visible.nil?

    areas = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |area| summary(area) }
    listing(:service_areas, areas, total: scope.count, narrow: 'query or visible')
  end

  def summary(area)
    { id: area.id, slug: area.slug, name: area.name, lang: area.lang, visible: area.visible,
      ordering: area.ordering }
  end

  def get(area)
    { id: area.id, slug: area.slug, name: area.name, lang: area.lang, visible: area.visible,
      is_training_program: area.is_training_program, ordering: area.ordering,
      icon: area.icon, side_image: area.side_image,
      primary_color: area.primary_color, secondary_color: area.secondary_color,
      primary_font_color: area.primary_font_color, secondary_font_color: area.secondary_font_color,
      target_title: area.target_title, value_proposition_title: area.value_proposition_title,
      seo_title: area.seo_title, seo_description: area.seo_description,
      blocks: BLOCKS.index_with { |field| area.public_send(field).body.to_s },
      recommended_way: { title: area.recommended_way_title, note: area.recommended_way_note,
                         summary: area.recommended_way_summary, details: area.recommended_way_details },
      services: area.services.order(:ordering).map { |s| { id: s.id, slug: s.slug, name: s.name } } }.to_json
  end

  def write(area, confirm:, visible:, **fields)
    action = area ? :update : :create
    return unauthorized(action, ServiceArea) unless ability.can?(action, ServiceArea)

    ServiceAreaWriteService.new(ability: ability, record: area, visible: visible, **fields)
                           .call(confirm: confirm).to_json
  end
end
