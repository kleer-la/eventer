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
    @active_menu = @time_segment
    if @time_segment.nil?
      redirect_to "/marketing/30"
    else
      @since = DateTime.now-36000
      @since = DateTime.now-@time_segment.to_i if @time_segment != "all"
      @camapigns = Campaign.where("updated_at >= ?", @since ).order("updated_at DESC")
    end
  end

  def campaign
    @time_segment = params[:time_segment]
    @active_menu = @time_segment
    if @time_segment.nil?
      redirect_to "marketing/campaigns/#{params[:id]}/30"
    else
      @since = DateTime.now-36000
      @since = DateTime.now-@time_segment.to_i if @time_segment != "all"
      @campaign = Campaign.find(params[:id])
    end
  end

  private

  def activate_menu
    @active_menu = "segmento"
  end

end
