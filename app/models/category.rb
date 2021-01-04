class Category < ActiveRecord::Base
  has_and_belongs_to_many :event_types
  
  attr_accessible :codename, :description, :name, :tagline, :description_en, :name_en, :tagline_en, :events, :visible, :order
  
  validates :name, :description, :codename, :tagline, :presence => true
  
  scope :visible_ones, where(:visible => true)
  scope :sorted, order("name DESC")  # Category.find(:all).sort{|p1,p2| p1.name <=> p2.name}
end
