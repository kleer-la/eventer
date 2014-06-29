class Trainer < ActiveRecord::Base
  belongs_to :country  
  has_and_belongs_to_many :event_types
  has_many :events
  has_many :participants, :through => :events
  
  scope :kleerer, where(:is_kleerer => true)
  
  validates :name, :presence => true
  
  def gravatar_picture_url
    hash = "asljasld"
    hash = Digest::MD5.hexdigest(self.gravatar_email) unless self.gravatar_email.nil?
    "http://www.gravatar.com/avatar/#{hash}"
  end
  
  def to_xml( options )
    super( options.merge(:methods =>  :gravatar_picture_url ) )
  end
    
end
