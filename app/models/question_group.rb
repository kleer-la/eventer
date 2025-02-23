class QuestionGroup < ApplicationRecord
  belongs_to :assessment
  has_many :questions, dependent: :destroy
end
