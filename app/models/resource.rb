# frozen_string_literal: true

class Resource < ApplicationRecord
  include Recommendable
  include FileSizeChecker
  extend FriendlyId
  friendly_id :title_es, use: %i[slugged history]

  include ImageReference

  references_images_in :cover_es, :cover_en,
                       text_fields: %i[getit_es getit_en]

  belongs_to :category, optional: true

  enum :format, { card: 0, book: 1, infographic: 2, canvas: 3,
                  guide: 4, game: 5, assessment: 6, video: 7, other: 8 }

  has_many  :authorships, -> { order(updated_at: :desc) }
  has_many  :authors, through: :authorships, source: :trainer
  has_many  :translations
  has_many  :translators, through: :translations, source: :trainer
  has_many :illustrations
  has_many :illustrators, through: :illustrations, source: :trainer
  has_one  :assessment, dependent: :nullify

  validates :format, presence: true
  validates :title_es, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description_es, presence: true, length: { maximum: 220 }
  before_save :strip_slug

  def should_generate_new_friendly_id?
    slug.blank? && (title_es_changed? || super)
  end

  def strip_slug
    slug&.strip!
  end

  def category_name
    category&.name
  end

  def downloadable
    getit_es.present?
  end

  def as_recommendation(lang: 'es')
    is_en = lang == 'en'
    super
      .merge('title' => is_en ? title_en : title_es)
      .merge('subtitle' => is_en ? description_en : description_es)
      .merge('cover' => is_en ? cover_en : cover_es)
      .merge('downloadable' => downloadable)
  end

  def title
    title_es
  end
  accepts_nested_attributes_for :recommended_contents, allow_destroy: true

  def self.ransackable_associations(_auth_object = nil)
    %w[authors authorships category illustrations illustrators recommended_contents
       recommended_items slugs translations translators]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[buyit_en buyit_es categories_id comments_en comments_es cover_en cover_es created_at
       description_en description_es format getit_en getit_es id id_value landing_en landing_es
       published
       long_description_es preview_en
       long_description_en preview_es
       share_link_en share_link_es share_text_en share_text_es slug tags_en tags_es title_en title_es trainers_id updated_at
       seo_description_en seo_description_es tabtitle_en tabtitle_es]
  end
end
