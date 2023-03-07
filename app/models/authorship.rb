# frozen_string_literal: true

class Authorship < ApplicationRecord
  belongs_to :resource
  belongs_to :trainer
end