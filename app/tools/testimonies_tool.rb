# frozen_string_literal: true

# Testimonies — what clients and participants said about a service or a course:
# one tool, four operations. Starring one is what shows it on the site.
class TestimoniesTool < AuthenticatedTool
  tool_name 'testimonies'
  requires_permission :read, Testimony

  OPERATIONS = %w[list get create update].freeze

  description <<~MD
    Testimonies: what clients and participants said about a Service or a
    course (event type). Only starred ones show on the site: on the course
    page, and on the page of the area a service belongs to (ten at most).

    operation=list (default): newest first, filtered by service (id or slug),
    event_type (id), service_area (id or slug: the testimonies of its
    services, i.e. what its page can show), starred, query (name).
    operation=get: one in full, by numeric id; the text comes as HTML.
    operation=create: needs first_name, last_name, and what it is about:
    service or event_type, exactly one. Not starred unless starred=true.
    operation=update: edits testimony `id`; only the fields passed are
    touched. Pass service or event_type to move it. To change part of the
    text, prefer `replacements` on `testimony`.

    Writes take two steps: confirm=false (the default) previews without saving;
    call again with confirm=true once the user agrees.
  MD

  arguments do
    optional(:operation).filled(:string).description("'list' (default), 'get', 'create' or 'update'")
    optional(:id).filled(:integer).description('get/update: numeric id of the testimony')
    optional(:query).filled(:string).description('list: substring matched against first or last name')
    optional(:service).filled(:string).description('list: filter. create/update: what it is about — service id or slug')
    optional(:event_type).filled(:string).description('list: filter. create/update: what it is about — course id')
    optional(:service_area).filled(:string).description('list: the testimonies of the services of this area (id/slug)')
    optional(:starred).filled(:bool).description('list: filter. create/update: shown on the site or not')
    optional(:limit).filled(:integer).description("list: how many (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
    optional(:first_name).filled(:string).description('First name of who said it')
    optional(:last_name).filled(:string).description('Last name of who said it')
    optional(:testimony).filled(:string).description('What they said; HTML accepted')
    optional(:profile_url).filled(:string).description('LinkedIn or other profile URL')
    optional(:photo_url).filled(:string).description('Photo URL')
    optional(:confirm).filled(:bool).description('create/update: false (default) = preview only; true = save')
    instance_exec(&ApplicationTool::REPLACEMENTS)
  end

  def call(operation: 'list', id: nil, confirm: false, limit: DEFAULT_LIMIT, starred: nil, **fields)
    case operation
    when 'list' then list(limit: limit, starred: starred, **fields.slice(:query, :service, :event_type, :service_area))
    when 'get' then get(find(id))
    when 'create' then write(nil, confirm: confirm, starred: starred, **fields.except(:query, :service_area))
    when 'update' then write(find(id), confirm: confirm, starred: starred, **fields.except(:query, :service_area))
    else unknown_operation(operation)
    end
  rescue ActiveRecord::RecordNotFound
    error("No testimony with id #{id.inspect}")
  end

  private

  def find(id)
    raise ActiveRecord::RecordNotFound if id.blank?

    Testimony.find(id)
  end

  def list(limit:, starred: nil, query: nil, **filters)
    scope = filtered(Testimony.includes(:testimonial, :rich_text_testimony).order(created_at: :desc), **filters)
    return error(scope) if scope.is_a?(String)

    scope = scope.where(stared: starred ? true : [false, nil]) unless starred.nil?
    scope = scope.where('first_name LIKE :q OR last_name LIKE :q', q: "%#{query}%") if query.present?

    items = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |testimony| summary(testimony) }
    listing(:testimonies, items, total: scope.count, narrow: 'service, event_type, service_area, starred or query')
  end

  # The scope narrowed to what the testimonies are about, or an error message.
  def filtered(scope, service: nil, event_type: nil, service_area: nil)
    scope = scope.where(testimonial: Service.friendly.find(service)) if service.present?
    scope = scope.where(testimonial: EventType.find(event_type.to_s[/\A\d+/] || event_type)) if event_type.present?
    service_area.present? ? within_area(scope, service_area) : scope
  rescue ActiveRecord::RecordNotFound
    "Unknown #{service.present? ? "service #{service.inspect}" : "event_type #{event_type.inspect}"}"
  end

  def within_area(scope, reference)
    area = ServiceArea.referenced_by(reference).first
    area ? scope.merge(area.testimonies) : "Unknown service area #{reference.inspect}"
  end

  def summary(testimony)
    { id: testimony.id, first_name: testimony.first_name, last_name: testimony.last_name,
      starred: testimony.stared == true, about: about(testimony.testimonial),
      excerpt: testimony.testimony.to_plain_text.truncate(120) }
  end

  def about(subject)
    return nil unless subject

    { type: subject.class.name, id: subject.id, slug: subject.try(:slug), name: subject.name }
  end

  def get(testimony)
    summary(testimony).except(:excerpt)
                      .merge(testimony: testimony.testimony.body.to_s, profile_url: testimony.profile_url,
                             photo_url: testimony.photo_url, updated_at: testimony.updated_at).to_json
  end

  def write(testimony, confirm:, starred:, **fields)
    action = testimony ? :update : :create
    return unauthorized(action, Testimony) unless ability.can?(action, Testimony)

    TestimonyWriteService.new(ability: ability, record: testimony, starred: starred, **fields)
                         .call(confirm: confirm).to_json
  end
end
