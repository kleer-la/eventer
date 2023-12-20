# frozen_string_literal: true

class Trainer < ApplicationRecord
  belongs_to :country, optional: true
  # has_and_belongs_to_many :event_types

  has_many :events
  has_many :cotrained_events, class_name: 'Event', foreign_key: 'trainer2_id'

  has_many :participants, through: :events
  has_many :cotrained_participants, through: :cotrained_events, source: :participants

  has_and_belongs_to_many :articles
  has_many :authorships
  has_many :resources, through: :authorships
  has_many :translations
  has_many :translators, through: :translations


  scope :kleerer, -> { where(is_kleerer: true) }
  scope :sorted, -> { where(deleted: false).order('name asc') }  # Trainer.find(:all).sort{|p1,p2| p1.name <=> p2.name}

  validates :name, presence: true

  def gravatar_picture_url
    hash = 'asljasld'
    hash = Digest::MD5.hexdigest(gravatar_email) unless gravatar_email.nil?
    "http://www.gravatar.com/avatar/#{hash}"
  end

  def to_xml(options)
    super(options.merge(methods: :gravatar_picture_url))
  end

  def self.ransackable_attributes(auth_object = nil)
    ["average_rating", "bio", "bio_en", "country_id", "created_at", "deleted", "gravatar_email", "id", "id_value", "is_kleerer", "landing", "linkedin_url", "name", "net_promoter_score", "promoter_count", "signature_credentials", "signature_image", "surveyed_count", "tag_name", "twitter_username", "updated_at"]
  end  
end
