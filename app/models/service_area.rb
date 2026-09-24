# frozen_string_literal: true

class ServiceArea < ApplicationRecord
  include Recommendable
  include RecommendedWayRenderable
  include ServiceOffering
  before_save :strip_slug
  extend FriendlyId
  friendly_id :name, use: %i[slugged history]

  include ImageReference
  references_images_in :icon, :side_image

  enum :lang, { es: 0, en: 1 }
  has_many :services, dependent: :destroy
  has_and_belongs_to_many :trainers

  has_rich_text :summary
  has_rich_text :slogan
  has_rich_text :subtitle
  has_rich_text :description
  has_rich_text :target
  has_rich_text :value_proposition
  has_rich_text :cta_message

  validates_presence_of %i[
    name summary icon slogan subtitle description side_image
    primary_color secondary_color cta_message
    seo_title seo_description
  ]

  accepts_nested_attributes_for :recommended_contents, allow_destroy: true

  def should_generate_new_friendly_id?
    slug.blank?
  end

  # The areas an MCP caller may mean by `reference`: a numeric id, a slug or a
  # name. A name is not unique — the same area exists once per language — so
  # this can return several, and the caller decides what to do with that.
  def self.referenced_by(reference)
    reference = reference.to_s.strip
    return where(id: reference) if reference.match?(/\A\d+\z/)

    by_slug = where(slug: reference)
    by_slug.exists? ? by_slug : where(name: reference)
  end

  # How an MCP response names the area without ambiguity.
  def reference
    "#{name} (id #{id}, slug #{slug}, lang #{lang})"
  end

  def to_mcp
    { id: id, slug: slug, name: name, lang: lang }
  end

  def title
    name
  end

  def testimonies
    Testimony.where(testimonial_type: 'Service', testimonial_id: service_ids)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[abstract created_at icon id id_value lang name primary_color secondary_color slug updated_at visible
       recommended_way_title recommended_way_note pricing brochure]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[services trainers]
  end

  private

  def strip_slug
    slug.strip! if slug.present?
  end
end
