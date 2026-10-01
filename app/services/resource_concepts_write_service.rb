# frozen_string_literal: true

# Loads the cards of a concepts resource in one call: each entry is upserted by
# slug + lang (only the fields given are touched) or removed with _destroy.
# Everything runs in a savepoint that only survives a confirmed, error-free
# call, so a preview or one bad card saves nothing.
#
# related_slugs are assigned in a second pass, once every card of the call
# exists, so new cards can point at each other.
class ResourceConceptsWriteService
  FIELDS = %i[position name question stage definition analogy misconception correction practice media].freeze
  LONG = %w[definition analogy misconception correction practice media].freeze

  def initialize(ability:, resource:, concepts:)
    @ability = ability
    @resource = resource
    @entries = Array(concepts).map { |entry| entry.to_h.symbolize_keys }
    @errors = []
    @results = []
  end

  def call(confirm: false)
    return failure if refused?

    ResourceConcept.transaction(requires_new: true) do
      apply
      raise ActiveRecord::Rollback unless confirm && @errors.empty?
    end
    return failure if @errors.any?

    { status: confirm ? 'saved' : 'preview', resource: @resource.slug, concepts: @results, warnings: warnings,
      note: confirm ? nil : 'Nothing was saved. Call again with confirm=true to apply these changes.' }.compact
  end

  private

  def refused?
    @errors << 'Nothing to do: pass `concepts`, a list of cards.' if @entries.empty?
    @errors << 'Your role cannot edit resources.' unless @ability.can?(:update, Resource)
    @errors << 'Only administrators can set `media` (it takes HTML).' if refused_media?
    @errors << 'Your role cannot delete concepts (_destroy).' if refused_destroy?
    @errors.any?
  end

  def refused_media?
    @entries.any? { |e| e.key?(:media) } && !@ability.can?(:set_media, ResourceConcept)
  end

  def refused_destroy?
    @entries.any? { |e| e[:_destroy] } && !@ability.can?(:destroy, ResourceConcept)
  end

  def apply
    pending = @entries.filter_map { |entry| upsert(entry) }
    pending.each { |concept, entry| relate(concept, entry) }
  end

  def upsert(entry)
    concept = find_concept(entry)
    return destroy(concept) if entry[:_destroy]

    action = concept.new_record? ? 'create' : 'update'
    concept.assign_attributes(entry.slice(*FIELDS))
    concept.position = next_position(concept.lang) if concept.new_record? && entry[:position].nil?
    return invalid(concept) unless concept.save

    @results << { slug: concept.slug, lang: concept.lang, action:, changes: shown(concept.saved_changes) }
    [concept, entry] if entry.key?(:related_slugs)
  end

  def find_concept(entry)
    slug = (entry[:slug].presence || entry[:name].to_s).parameterize
    @resource.concepts.find_or_initialize_by(lang: entry[:lang].presence || 'es', slug:)
  end

  def relate(concept, entry)
    concept.related_slugs = Array(entry[:related_slugs]).join(',')
    return invalid(concept) unless concept.save

    result = @results.find { |r| r[:slug] == concept.slug && r[:lang] == concept.lang }
    result[:changes].merge!(shown(concept.saved_changes))
  end

  def destroy(concept)
    if concept.new_record?
      @errors << "#{concept.slug} (#{concept.lang}): no such concept to delete"
    else
      concept.destroy!
      @results << { slug: concept.slug, lang: concept.lang, action: 'destroy' }
    end
    nil
  end

  def next_position(lang)
    (@resource.concepts.where(lang:).maximum(:position) || 0) + 1
  end

  def invalid(concept)
    @errors << "#{concept.slug.presence || concept.name} (#{concept.lang}): #{concept.errors.full_messages.join('; ')}"
    nil
  end

  def shown(changes)
    changes.except('id', 'resource_id', 'created_at', 'updated_at', 'lang', 'slug').to_h do |field, (_, value)|
      [field, LONG.include?(field) ? value.to_s.truncate(120) : value]
    end
  end

  def warnings
    warnings = []
    unless @resource.concepts?
      warnings << "The resource's format is '#{@resource.format}': the site shows cards only for format 'concepts'."
    end
    warnings + dangling_relations
  end

  # A card deleted in this call may still be listed as related by another one.
  def dangling_relations
    @resource.concepts.reload.group_by(&:lang).flat_map do |lang, cards|
      slugs = cards.map(&:slug)
      cards.filter_map do |card|
        missing = card.related - slugs
        "#{card.slug} (#{lang}) still relates to #{missing.join(', ')}, which does not exist" if missing.any?
      end
    end
  end

  def failure
    { status: 'invalid', errors: @errors, note: 'Nothing was saved.' }
  end
end
