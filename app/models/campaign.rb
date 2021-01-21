class Campaign < ActiveRecord::Base
  has_many :campaign_views
  has_many :countries, -> { uniq }, through: :events
  has_many :participants
  attr_accessible :codename, :description

  scope :real, -> {where("codename <> ''")}
  scope :fake, -> {where("codename == NULL")}

  def display_name
    (!self.codename.nil? && self.codename != "") ? self.codename : "n/a"
  end

  def events(since, untilll)
    @event_ids = campaign_views.where("created_at >= ?", since).where("created_at < ?", untilll).map{ |p| p.event_id }
    Event.where('id in (?)', @event_ids ).order('created_at DESC')
  end

  def event_types(since, untilll)
    @event_ids = events(since,untilll).map{ |p| p.event_type_id }
    EventType.where('id in (?)', @event_ids ).order('created_at DESC')
  end

  def campaign_sources(since, untilll)
    @source_ids = campaign_views.where("created_at >= ?", since).where("created_at < ?", untilll).map{ |p| p.campaign_source_id }
    CampaignSource.where('id in (?)', @source_ids ).order('created_at DESC')
  end
end
