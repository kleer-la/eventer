class ServiceArea < ApplicationRecord
  validates_presence_of :name
  has_rich_text :abstract
end
