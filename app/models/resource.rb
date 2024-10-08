# frozen_string_literal: true

class Resource < ApplicationRecord
  include Recommendable
  extend FriendlyId
  friendly_id :title_es, use: %i[slugged history]
  belongs_to :category, optional: true

  enum format: { card: 0, book: 1, infographic: 2, canvas: 3,
                 guide: 4, game: 5 }

  has_many  :authorships, -> { order(updated_at: :desc) }
  has_many  :authors, through: :authorships, source: :trainer
  has_many  :translations
  has_many  :translators, through: :translations, source: :trainer
  has_many :illustrations
  has_many :illustrators, through: :illustrations, source: :trainer

  validates :format, presence: true
  validates :title_es, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description_es, presence: true, length: { maximum: 220 }
  before_save :strip_slug

  def should_generate_new_friendly_id?
    title_es_changed? || super
  end

  def strip_slug
    slug&.strip!
  end

  def category_name
    category&.name
  end

  def as_recommendation
    super
      .merge('title' => title)
      .merge('subtitle' => description_es)
      .merge('cover' => cover_es)
  end

  def title
    title_es
  end
end
