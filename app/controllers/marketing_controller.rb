class MarketingController < ApplicationController
  def index
    @camapigns = Campaign.order("created_at DESC")
  end

  def campaign
    @campaign = Campaign.find(params[:id])
    @sources = @campaign.campaign_views.group(:source).count
  end
end
