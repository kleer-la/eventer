# frozen_string_literal: true

# Course types — the template a course is given from, and what a certificate
# names: one tool, four operations.
class EventTypesTool < AuthenticatedTool
  tool_name 'event_types'
  requires_permission :read, EventType

  OPERATIONS = %w[list get create update].freeze
  BLOCKS = %i[description recipients program goal learnings takeaways faq].freeze

  description <<~MD
    Course types: the template a course is given from, and the name, duration
    and seal that end up printed on the certificate. A course given twice is
    two events of one type, not two types — look for an existing one first.

    operation=list (default): filtered by query (name), lang, in_catalog. Use it
    to find the id an event needs.
    operation=get: one course type in full, by id (slug or numeric): the blocks
    that make up its page (description, recipients, program, goal, learnings,
    takeaways, faq), what the certificate says, and who teaches it.
    operation=create: needs name, description, recipients, program,
    elevator_pitch and trainers. Always created out of the public catalog:
    putting a course on sale is done from the admin, on purpose.
    operation=update: edits course type `id`; only the fields passed are
    touched. To change part of a block, prefer `replacements` (it patches the
    blocks) — which is how a stale link inside a course page gets fixed.
    Whether a course is on sale is not an argument here.

    Writes take two steps: confirm=false (the default) validates and returns a
    preview without saving; call again with confirm=true once the user agrees.
  MD

  arguments do
    optional(:operation).filled(:string).description("'list' (default), 'get', 'create' or 'update'")
    optional(:id).filled(:string).description('get/update: course slug (preferred) or numeric id')
    optional(:query).filled(:string).description('list: substring matched against the name')
    optional(:lang).filled(:string).description("Language: 'es' or 'en' (list: filter; create: default es)")
    optional(:in_catalog).filled(:bool).description('list: true = only the ones on sale on the site')
    optional(:limit).filled(:integer).description("list: how many (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
    optional(:name).filled(:string).description('Course name, as it should read on the certificate')
    optional(:description).filled(:string).description('What the course is')
    optional(:recipients).filled(:string).description('Who it is for')
    optional(:program).filled(:string).description('Contents')
    optional(:elevator_pitch).filled(:string).description('One-line pitch, at most 160 characters')
    optional(:trainers).array(:string).description('Trainer names, exactly as they are in the admin')
    optional(:duration).filled(:integer).description('Hours, the number printed on the certificate')
    optional(:goal).filled(:string).description('Objective')
    optional(:learnings).filled(:string).description('What the participant learns')
    optional(:takeaways).filled(:string).description('What the participant takes home')
    optional(:faq).filled(:string)
                  .description('Questions and answers, each one an `<h4>` heading followed by its answer')
    optional(:tag_name).filled(:string).description('Short tag used in listings')
    optional(:subtitle).filled(:string).description('Subtitle')
    optional(:is_kleer_certification).filled(:bool)
                                     .description('true = a Kleer certification; needs kleer_cert_seal_image')
    optional(:kleer_cert_seal_image).filled(:string).description('Seal image file name for the certificate')
    optional(:csd_eligible).filled(:bool).description('true = counts towards Scrum Alliance CSD')
    optional(:new_version).filled(:bool).description('update: true = the newer edition of the course')
    optional(:confirm).filled(:bool).description('create/update: false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  def call(operation: 'list', id: nil, confirm: false, limit: DEFAULT_LIMIT, **fields)
    case operation
    when 'list' then list(limit: limit, **fields.slice(:query, :lang, :in_catalog))
    when 'get' then get(find(id))
    when 'create' then write(nil, confirm: confirm, **fields.except(:query, :in_catalog))
    when 'update' then write(find(id), confirm: confirm, **fields.except(:query, :in_catalog))
    else unknown_operation(operation)
    end
  rescue ActiveRecord::RecordNotFound
    error("No course type with slug or id #{id.inspect}")
  end

  private

  def find(id)
    raise ActiveRecord::RecordNotFound if id.blank?

    EventType.find(id.to_s[/\A\d+/] || id)
  end

  def list(limit:, query: nil, lang: nil, in_catalog: nil)
    scope = EventType.includes(:trainers).order(:name)
    scope = scope.where('name LIKE ?', "%#{query}%") if query.present?
    scope = scope.where(lang: lang) if lang.present?
    scope = scope.where(include_in_catalog: in_catalog) unless in_catalog.nil?

    types = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |type| summary(type) }
    listing(:event_types, types, total: scope.count, narrow: 'query, lang or in_catalog')
  end

  def summary(type)
    { id: type.id, name: type.name, lang: type.lang, duration: type.duration,
      include_in_catalog: type.include_in_catalog, is_kleer_certification: type.is_kleer_certification,
      trainers: type.trainers.map(&:name) }
  end

  def get(event_type)
    identity(event_type)
      .merge(flags(event_type))
      .merge(blocks: BLOCKS.index_with { |field| event_type.public_send(field).to_s })
      .to_json
  end

  def identity(event_type)
    { id: event_type.id, slug: event_type.slug, name: event_type.name, lang: event_type.lang,
      subtitle: event_type.subtitle, elevator_pitch: event_type.elevator_pitch,
      tag_name: event_type.tag_name, duration: event_type.duration,
      trainers: event_type.trainers.map(&:name) }
  end

  def flags(event_type)
    { in_catalog: event_type.include_in_catalog, deleted: event_type.deleted, noindex: event_type.noindex,
      is_kleer_certification: event_type.is_kleer_certification, csd_eligible: event_type.csd_eligible,
      kleer_cert_seal_image: event_type.kleer_cert_seal_image, new_version: event_type.new_version,
      seo_title: event_type.seo_title, external_site_url: event_type.external_site_url }
  end

  def write(event_type, confirm:, **fields)
    action = event_type ? :update : :create
    return unauthorized(action, EventType) unless ability.can?(action, EventType)

    EventTypeWriteService.new(ability: ability, record: event_type, **fields).call(confirm: confirm).to_json
  end
end
