class Answer < ApplicationRecord
  include ImageReference
  references_images_in text_fields: [:text]
  belongs_to :question
end
