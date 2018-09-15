class Campaign < ActiveRecord::Base
  has_many :campaign_views
  #has_many :events, through: :campaign_views, uniq: true
  #has_many :event_types, through: :events, uniq: true
  has_many :countries, through: :events, uniq: true
  has_many :campaign_sources, through: :campaign_views, uniq: true
  has_many :participants
  attr_accessible :codename, :description

  def display_name
    (!self.codename.nil? && self.codename != "") ? self.codename : "n/a"
  end

  def events(since)
    @event_ids = campaign_views.where("created_at >= ?", since).map{ |p| p.event_id }
    Event.where('id in (?)', @event_ids ).order('created_at DESC')
  end

  def event_types(since)
    @event_type_ids = events(since).map{ |p| p.event_type_id }
    EventType.where('id in (?)', @event_type_ids ).order('created_at DESC')
  end
end
