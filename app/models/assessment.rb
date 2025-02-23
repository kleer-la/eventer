class Assessment < ApplicationRecord
  has_many :question_groups, dependent: :destroy
  has_many :questions, dependent: :destroy
  has_many :contacts, dependent: :destroy
end
