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
end
