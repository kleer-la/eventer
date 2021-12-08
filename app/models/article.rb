class Article < ApplicationRecord
    validates :title, presence: true
    validates :body, presence: true
    # validates :published, presence: true
    validates :slug, presence: true
    validates :description, presence: true, length: { maximum: 160 }   
end
