class Category < ApplicationRecord
  has_and_belongs_to_many :event_types
  
  validates :name, :description, :codename, :tagline, :presence => true
  
  scope :visible_ones, -> {where(:visible => true)}
  scope :sorted, -> {order("name DESC")}  # Category.find(:all).sort{|p1,p2| p1.name <=> p2.name}
end
