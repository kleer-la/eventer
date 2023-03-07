# frozen_string_literal: true

class Resource < ApplicationRecord
  extend FriendlyId
  friendly_id :title_es, use: :slugged
  belongs_to :category

  enum format: { card: 0, book: 1, infographic: 2, canvas: 3, guide: 4 } # example of enum definition
  
  has_many  :authorships
  has_many  :authors, through: :authorships, source: :trainer
  # has_and_belongs_to_many  :translators, class_name: 'Trainer'
  
  validates :format, presence: true
  validates :title_es, presence: true, length: { minimum: 2, maximum: 100 }

  # validates :title, presence: true
  # validates :description, presence: true, length: { maximum: 160 }
  
  # def should_generate_new_friendly_id?
  #   !slug.present?
  # end
  
  def category_name
    category&.name
  end
end
