# frozen_string_literal: true

class Illustration < ApplicationRecord
  belongs_to :resource
  belongs_to :trainer
end
