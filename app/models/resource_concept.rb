# frozen_string_literal: true

# One card of a "concepts" resource. The stage is free text; stages are read in
# the order of the first position of their concepts.
class ResourceConcept < ApplicationRecord
  LANGS = %w[es en].freeze
  # The text fields where [[slug]] or [[slug|texto]] links to another card of
  # the same resource and language; the site turns the mark into the link
  # (kleer-la/website17#433), the API sends the text as it is (#226).
  LINKABLE_FIELDS = %i[definition analogy misconception correction practice].freeze
  LINK_HINT = 'Enlace a otra ficha: [[slug]] muestra su nombre, [[slug|texto]] muestra el texto'
  LINK_MARK = /\[\[([^\]|]+)(?:\|[^\]]*)?\]\]/

  belongs_to :resource, touch: true
  extend FriendlyId
  friendly_id :name, use: %i[slugged scoped], scope: %i[resource lang]

  validates :name, :stage, :definition, presence: true
  validates :lang, inclusion: { in: LANGS }
  validates :slug, uniqueness: { scope: %i[resource_id lang] }
  validate :related_concepts_exist
  validate :linked_concepts_exist, unless: :defer_link_check

  # Loading several cards in one call, the links are checked once all of them
  # exist, so new cards can link to each other (ResourceConceptsWriteService).
  attr_accessor :defer_link_check

  def should_generate_new_friendly_id?
    slug.blank?
  end

  def resolve_friendly_id_conflict(candidates)
    candidates.first
  end

  # The slug repeats across languages, so the admin addresses a card by id.
  def to_param
    id&.to_s
  end

  def related
    related_slugs.to_s.split(',').map(&:strip).compact_blank
  end

  # The slugs a field links to; the slug of every card it links to, given none.
  def linked_slugs(field = nil)
    fields = field ? [field] : LINKABLE_FIELDS
    fields.flat_map { |f| public_send(f).to_s.scan(LINK_MARK).flatten.map(&:strip) }.uniq
  end

  def as_api_json
    as_json(only: %i[slug lang position name question stage definition analogy misconception
                     correction practice media updated_at])
      .merge('related_slugs' => related)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[lang name position slug stage resource_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  private

  def related_concepts_exist
    return if related.empty? || resource.nil?

    known = ResourceConcept.where(resource_id:, lang:).pluck(:slug)
    missing = related - known - [slug]
    return if missing.empty?

    errors.add(:related_slugs, "no son conceptos de este recurso en '#{lang}': #{missing.join(', ')}")
  end

  def linked_concepts_exist
    return if resource.nil? || linked_slugs.empty?

    known = ResourceConcept.where(resource_id:, lang:).pluck(:slug) + [slug]
    LINKABLE_FIELDS.each do |field|
      missing = linked_slugs(field) - known
      next if missing.empty?

      errors.add(field, "enlaza a conceptos que no son de este recurso en '#{lang}': #{missing.join(', ')}")
    end
  end
end
