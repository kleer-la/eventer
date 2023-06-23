class News < ApplicationRecord
  has_and_belongs_to_many :trainers
  enum lang: %i[es en]
end
