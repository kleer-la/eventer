# frozen_string_literal: true

# Services: one tool, four operations. The page blocks are rich text (HTML).
class ServicesTool < AuthenticatedTool
  tool_name 'services'
  requires_permission :read, Service

  OPERATIONS = %w[list get create update].freeze
  BLOCKS = %i[value_proposition outcomes definitions program target faq].freeze

  description <<~MD
    The services offered, grouped by service area.

    operation=list (default): summaries in display order, filtered by query
    (name), service_area, published. Long texts are not included.
    operation=get: one service in full, by id (slug or numeric): the rich-text
    blocks that make up its page (value proposition, outcomes, definitions,
    program, target, FAQ), the recommended-way copy, and what it recommends.
    operation=create: needs name, subtitle, service_area, value_proposition,
    outcomes, program, target and side_image; unpublished unless published=true.
    operation=update: edits service `id`; only the fields passed are touched.
    A block passed whole replaces the whole block — read it first. To change
    part of one, prefer `replacements`, matched against that HTML (it patches
    the blocks, card_description, recommended_way_summary and _details).

    Writes take two steps: confirm=false (the default) previews without saving.
  MD

  arguments do
    optional(:operation).filled(:string).description("'list' (default), 'get', 'create' or 'update'")
    optional(:id).filled(:string).description('get/update: service slug (preferred) or numeric id')
    optional(:query).filled(:string).description('list: substring matched against the name')
    optional(:service_area).filled(:string).description('Service area name (list: filter; create: required)')
    optional(:published).filled(:bool).description('list: filter. create/update: on the site or not')
    optional(:limit).filled(:integer).description("list: how many (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
    optional(:name).filled(:string).description('Service name')
    optional(:subtitle).filled(:string).description('One-line subtitle')
    optional(:slug).filled(:string).description('URL slug; derived from the name when omitted')
    optional(:value_proposition).filled(:string).description('Value proposition block; HTML accepted')
    optional(:outcomes).filled(:string).description('Outcomes block; HTML accepted')
    optional(:definitions).filled(:string).description('Definitions block; HTML accepted')
    optional(:program).filled(:string).description('Program block; HTML accepted')
    optional(:target).filled(:string).description('Who it is for; HTML accepted')
    optional(:faq).filled(:string).description('FAQ block; HTML accepted')
    optional(:card_description).filled(:string).description('Short text for the listing card')
    optional(:pricing).filled(:string).description('Pricing note')
    optional(:side_image).filled(:string).description('Side image URL')
    optional(:brochure).filled(:string).description('Brochure URL')
    optional(:ordering).filled(:integer).description('Display order within the area')
    optional(:seo_title).filled(:string).description('SEO title')
    optional(:seo_description).filled(:string).description('SEO description')
    optional(:recommended_way_title).filled(:string).description('Recommended-way title')
    optional(:recommended_way_note).filled(:string).description('Recommended-way note')
    optional(:recommended_way_summary).filled(:string).description('Recommended-way summary')
    optional(:recommended_way_details).filled(:string).description('Recommended-way details')
    optional(:confirm).filled(:bool).description('create/update: false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  # The operation is looked up in OPERATIONS before `send`, so only these four
  # methods are reachable from a client.
  def call(operation: 'list', **args)
    return unknown_operation(operation) unless OPERATIONS.include?(operation)

    send(operation, **args)
  rescue ActiveRecord::RecordNotFound
    error("No service with slug or id #{args[:id].inspect}")
  end

  private

  def find(id)
    raise ActiveRecord::RecordNotFound if id.blank?

    Service.friendly.find(id)
  end

  def list(limit: DEFAULT_LIMIT, query: nil, service_area: nil, published: nil, **)
    scope = Service.includes(:service_area).order(:ordering, :name)
    scope = scope.where('name LIKE ?', "%#{query}%") if query.present?
    scope = scope.joins(:service_area).where(service_areas: { name: service_area }) if service_area.present?
    scope = scope.where(published: published) unless published.nil?

    services = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |service| summary(service) }
    listing(:services, services, total: scope.count, narrow: 'query, service_area or published')
  end

  def summary(service)
    { id: service.id, slug: service.slug, name: service.name, subtitle: service.subtitle,
      service_area: service.service_area&.name, published: service.published, ordering: service.ordering }
  end

  def get(id: nil, **)
    service = find(id)
    { id: service.id, slug: service.slug, name: service.name, subtitle: service.subtitle,
      service_area: service.service_area&.name, published: service.published, ordering: service.ordering,
      card_description: service.card_description, pricing: service.pricing,
      side_image: service.side_image, brochure: service.brochure,
      seo_title: service.seo_title, seo_description: service.seo_description,
      blocks: BLOCKS.index_with { |field| service.public_send(field).body.to_s },
      recommended_way: { title: service.recommended_way_title, note: service.recommended_way_note,
                         summary: service.recommended_way_summary, details: service.recommended_way_details },
      recommends: service.recommended_contents.includes(:target).map do |content|
        { target_type: content.target_type, target_id: content.target_id,
          target: content.target&.try(:title) || content.target&.try(:name),
          relevance_order: content.relevance_order }
      end }.to_json
  end

  def create(confirm: false, published: false, service_area: nil, **fields)
    write(nil, confirm: confirm, published: published, service_area: service_area, **fields)
  end

  def update(id: nil, confirm: false, published: nil, service_area: nil, **fields)
    write(find(id), confirm: confirm, published: published, service_area: service_area, **fields)
  end

  def write(service, confirm:, published:, service_area:, **fields)
    action = service ? :update : :create
    return unauthorized(action, Service) unless ability.can?(action, Service)

    ServiceWriteService.new(ability: ability, record: service, service_area: service_area, published: published,
                            **fields.except(:query, :limit)).call(confirm: confirm).to_json
  end
end
