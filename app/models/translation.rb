# frozen_string_literal: true

class Translation < ApplicationRecord
  belongs_to :resource
  belongs_to :trainer
end
