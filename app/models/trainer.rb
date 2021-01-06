class Trainer < ActiveRecord::Base
  belongs_to :country
  has_and_belongs_to_many :event_types

  has_many :events
  has_many :cotrained_events, :class_name => "Event", :foreign_key => 'trainer2_id'

  has_many :participants, :through => :events
  has_many :cotrained_participants, :through => :cotrained_events, :source => :participants

  scope :kleerer, where(:is_kleerer => true)
  scope :sorted, order("name DESC")  # Trainer.find(:all).sort{|p1,p2| p1.name <=> p2.name}

  validates :name, :presence => true

  attr_accessible :name, :bio, :bio_en, :gravatar_email, :twitter_username, :linkedin_url, :tag_name, :signature_image, :signature_credentials, :is_kleerer


  def gravatar_picture_url
    hash = "asljasld"
    hash = Digest::MD5.hexdigest(self.gravatar_email) unless self.gravatar_email.nil?
    "http://www.gravatar.com/avatar/#{hash}"
  end

  def to_xml( options )
    super( options.merge(:methods =>  :gravatar_picture_url ) )
  end
end
