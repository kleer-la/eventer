# frozen_string_literal: true

class CampaignView < ApplicationRecord
  belongs_to :event
  belongs_to :event_type
  belongs_to :campaign
  belongs_to :campaign_source

  after_create do |view|
    view.campaign&.touch
    view.campaign_source&.touch
  end
end
