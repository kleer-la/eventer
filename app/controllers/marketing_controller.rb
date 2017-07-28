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
    @camapigns = Campaign.order("updated_at DESC")
  end

  def campaign
    @campaign = Campaign.find(params[:id])
  end

  private

  def activate_menu
    @active_menu = "marketing"
  end

end
