# frozen_string_literal: true

class Page < ApplicationRecord
  include Recommendable
  extend FriendlyId
  friendly_id :name, use: %i[slugged history scoped], scope: :lang

  include ImageReference
  references_images_in :cover

  has_many :sections, dependent: :destroy
  accepts_nested_attributes_for :sections, allow_destroy: true

  enum :lang, %w[es en]

  validates :name, presence: true
  validates :lang, presence: true
  validates :slug, uniqueness: { scope: :lang, allow_nil: true }
  validates :cover, presence: true, allow_blank: true

  scope :en, -> { where(lang: :en) }
  scope :es, -> { where(lang: :es) }

  before_validation :normalize_slug
  before_save :strip_slug

  def self.find_by_param!(param_id)
    lang, *slug_parts = param_id.split('-')
    slug = slug_parts.join('-')

    if slug.present?
      where(lang:).friendly.find(slug)
    else
      find_by!(lang:, slug: nil)
    end
  end

  def should_generate_new_friendly_id?
    !home_page? && (slug.blank? || saved_change_to_name?)
  end

  def display_name
    "#{name} - #{lang}"
  end

  def home_page?
    name&.downcase == 'home'
  end

  def to_param
    home_page? ? lang : "#{lang}-#{slug}"
  end

  def seo
    {
      seo_title:,
      seo_description:,
      lang:,
      canonical: canonical || default_canonical
    }
  end

  def as_recommendation(lang: 'es')
    super
      .merge('subtitle' => seo_description)
      .merge('slug' => slug)
      .merge('title' => title)
  end

  def title
    display_name || seo_title
  end

  accepts_nested_attributes_for :recommended_contents, allow_destroy: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[name seo_title seo_description lang slug canonical visible created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    ['slugs']
  end

  private

  def strip_slug
    slug&.strip!
  end

  def default_canonical
    home_page? ? '' : slug
  end

  def normalize_slug
    self.slug = nil if slug.blank?
  end
end
