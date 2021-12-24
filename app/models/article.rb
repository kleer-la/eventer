class Article < ApplicationRecord
  extend FriendlyId
  friendly_id :title, :use => [:slugged]
  has_and_belongs_to_many :trainers

  validates :title, presence: true
  validates :body, presence: true
  # validates :published, presence: true
  validates :description, presence: true, length: { maximum: 160 }

  def should_generate_new_friendly_id?
    !slug.present?
  end

  def abstract
    max_abstract_length= 500
    p body
    double_n = body.index("\r\n\r\n")
    double_n = double_n || max_abstract_length
    p = body.index('</p>')
    p += 4 unless p.nil?
    p = p || max_abstract_length
    abstract_end = double_n < p ? double_n : p 
    body[0...abstract_end]
  end
end
