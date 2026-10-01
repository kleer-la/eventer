# frozen_string_literal: true

# One card of a "concepts" resource. The stage is free text; stages are read in
# the order of the first position of their concepts.
class ResourceConcept < ApplicationRecord
  LANGS = %w[es en].freeze

  belongs_to :resource, touch: true
  extend FriendlyId
  friendly_id :name, use: %i[slugged scoped], scope: %i[resource lang]

  validates :name, :stage, :definition, presence: true
  validates :lang, inclusion: { in: LANGS }
  validates :slug, uniqueness: { scope: %i[resource_id lang] }
  validate :related_concepts_exist

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
end
