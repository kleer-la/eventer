# frozen_string_literal: true

class Article < ApplicationRecord
  include Recommendable
  extend FriendlyId
  friendly_id :title, use: [:slugged, :history]
  has_and_belongs_to_many :trainers
  enum lang: %i[es en]
  belongs_to :category, optional: true

  validates :title, presence: true
  validates :body, presence: true
  # validates :published, presence: true
  validates :description, presence: true, length: { maximum: 160 }

  def should_generate_new_friendly_id?
    !slug.present?
  end

  # TODO: deprecated!
  def abstract
    max_abstract_length = 500
    double_n = body.index("\r\n\r\n")
    double_n ||= max_abstract_length
    parag = body.index('</p>')
    parag += 4 unless parag.nil?
    parag ||= max_abstract_length
    abstract_end = double_n < parag ? double_n : parag
    body[0...abstract_end]
  end

  def category_name
    category&.name
  end
end
