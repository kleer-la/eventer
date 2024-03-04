class ServiceArea < ApplicationRecord
  validates_presence_of :name
  has_rich_text :abstract
  enum lang: { sp: 0, en: 1 }

  has_many :services, dependent: :destroy
end
