class MarketingController < ApplicationController
  before_filter :authenticate_user!, :except => [:viewed]
  before_filter :activate_menu

  def viewed
    @event = Event.find(params[:id])
    utm_campaign = params[:utm_campaign]
    utm_source = params[:utm_source]
    utm_campaign = utm_campaign.downcase unless utm_campaign.nil?
    utm_source = utm_source.downcase unless utm_source.nil?

    if !@event.nil?
      source = CampaignSource.where(codename: utm_source).first_or_create
      campaign = Campaign.where(codename: utm_campaign).first_or_create

      CampaignView.create( campaign: campaign, campaign_source: source, event: @event, element_viewed: "landing" )
    end

    respond_to do |format|
      format.gif {
        redirect_to '/images/1x1.gif'
      }
    end
  end

  def index
    @time_segment = params[:time_segment]
    @active_menu = "marketing"
    if @time_segment.nil?
      redirect_to "/marketing/30"
    else
      if @time_segment.is_integer?
        @since = DateTime.now-@time_segment.to_i
        @until = DateTime.now
      elsif @time_segment == "30-60"
        @since = DateTime.now-60
        @until = DateTime.now-30
      elsif @time_segment == "60-120"
        @since = DateTime.now-120
        @until = DateTime.now-60
      elsif @time_segment == "90-180"
        @since = DateTime.now-180
        @until = DateTime.now-90
      else
        @since = DateTime.now-36000
      end
      @camapign_ids = CampaignView.where("updated_at >= ?", @since ).where("updated_at < ?", @until ).map{ |p| p.campaign_id }
      @camapigns = Campaign.where('id in (?)', @camapign_ids ).order('updated_at DESC')
    end
  end

  def campaign
    @time_segment = params[:time_segment]
    @active_menu = "marketing"
    if @time_segment.nil?
      redirect_to "marketing/campaigns/#{params[:id]}/30"
    else
      if @time_segment.is_integer?
        @since = DateTime.now-@time_segment.to_i
        @until = DateTime.now
      elsif @time_segment == "30-60"
        @since = DateTime.now-60
        @until = DateTime.now-30
      elsif @time_segment == "60-120"
        @since = DateTime.now-120
        @until = DateTime.now-60
      elsif @time_segment == "90-180"
        @since = DateTime.now-180
        @until = DateTime.now-90
      else
        @since = DateTime.now-36000
      end
      @campaign = Campaign.find(params[:id])
    end
  end

  private

  def activate_menu
    @active_menu = "segmento"
  end

end
