# frozen_string_literal: true

# Cross references between entities: what an article, resource, service, event
# type or page recommends. In the admin these are edited as nested attributes
# of the source, so the permission that governs them is the right to update the
# *source* — that is what gets checked here, not a separate rule.
class RecommendationService
  SOURCE_TYPES = %w[Article Resource EventType Service Page].freeze
  TARGET_TYPES = %w[Article Resource EventType Service Page].freeze
  DEFAULT_RELEVANCE = 50

  def initialize(ability:, source_type:, source_id:)
    @ability = ability
    @source_type = source_type
    @source_id = source_id
  end

  def list
    return error unless source

    { source: describe(source), count: source.recommended_contents.size,
      recommends: source.recommended_contents.includes(:target).order(:relevance_order).map { |c| describe_link(c) } }
  end

  def add(target_type:, target_id:, relevance_order: DEFAULT_RELEVANCE, confirm: false)
    return error unless source && editable? && target(target_type, target_id)

    existing = link_to(@target)
    return already_recommended(existing) if existing&.relevance_order == relevance_order

    link = existing || source.recommended_contents.build(target: @target)
    link.relevance_order = relevance_order
    return { status: 'error', errors: link.errors.full_messages } unless link.valid?

    return preview_add(link, existing) unless confirm

    link.save!
    { status: 'saved', action: existing ? 'reordered' : 'added', source: describe(source),
      recommendation: describe_link(link) }
  end

  def remove(target_type:, target_id:, confirm: false)
    return error unless source && editable? && target(target_type, target_id)

    link = link_to(@target)
    if link.nil?
      return { status: 'error',
               errors: ["#{describe(@target)[:label]} is not recommended by #{describe(source)[:label]}"] }
    end

    unless confirm
      return { status: 'preview', removing: describe_link(link), source: describe(source),
               note: 'Nothing was removed. Call again with confirm=true to remove it.' }
    end

    link.destroy!
    { status: 'saved', action: 'removed', source: describe(source), removed: describe_link(link) }
  end

  private

  def already_recommended(existing)
    { status: 'error',
      errors: ["#{describe(@target)[:label]} is already recommended with relevance " \
               "#{existing.relevance_order}; pass a different relevance_order to move it, or remove it"] }
  end

  def preview_add(link, existing)
    { status: 'preview', source: describe(source),
      action: existing ? 'reorder' : 'add', recommendation: describe_link(link),
      note: 'Nothing was saved. Call again with confirm=true to apply it.' }
  end

  def source
    return @source if defined?(@source)

    @source = find(@source_type, @source_id, SOURCE_TYPES)
  end

  def target(type, id)
    @target = find(type, id, TARGET_TYPES)
  end

  def editable?
    return true if @ability.can?(:update, source)

    errors << "You are not allowed to edit #{describe(source)[:label]}"
    false
  end

  def link_to(target)
    source.recommended_contents.find_by(target_type: target.class.name, target_id: target.id)
  end

  # Accepts a slug, a numeric id, or the name/title of the entity.
  def find(type, identifier, allowed)
    unless allowed.include?(type)
      errors << "#{type.inspect} is not one of: #{allowed.join(', ')}"
      return nil
    end

    model = type.constantize
    record = by_slug(model, identifier) || by_id(model, identifier) || by_name(model, identifier)
    return record if record

    errors << "No #{type} matching #{identifier.inspect}"
    nil
  end

  def by_slug(model, identifier)
    model.respond_to?(:friendly) ? model.friendly.find(identifier) : nil
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def by_id(model, identifier)
    identifier.to_s.match?(/\A\d+\z/) ? model.find_by(id: identifier) : nil
  end

  def by_name(model, identifier)
    column = %w[name title_es title].find { |candidate| model.column_names.include?(candidate) }
    column ? model.find_by(column => identifier) : nil
  end

  def describe(record)
    { type: record.class.name, id: record.id, label: record.try(:title) || record.try(:name),
      slug: record.try(:slug) }.compact
  end

  def describe_link(link)
    { target_type: link.target_type, target_id: link.target_id,
      target: link.target && describe(link.target)[:label],
      relevance_order: link.relevance_order,
      level: source.calculate_level(link.relevance_order) }
  end

  def error = { status: 'error', errors: errors }

  def errors = @errors ||= []
end
