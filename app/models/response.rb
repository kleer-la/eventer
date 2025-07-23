class Response < ApplicationRecord
  belongs_to :contact
  belongs_to :question
  belongs_to :answer, optional: true

  validates :answer, presence: true, if: -> { question&.linear_scale? || question&.radio_button? }
  validates :text_response, presence: true, if: -> { question&.short_text? || question&.long_text? }
  validates :answer, absence: true, if: -> { question&.short_text? || question&.long_text? }
  validates :text_response, absence: true, if: -> { question&.linear_scale? || question&.radio_button? }
end
