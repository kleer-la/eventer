# frozen_string_literal: true

class CampaignSource < ApplicationRecord
  has_many :campaign_views
  has_many :events, -> { uniq }, through: :campaign_views
  has_many :event_types, -> { uniq }, through: :events
  has_many :countries, -> { uniq }, through: :events
  has_many :participants

  def display_name
    !codename.nil? && codename != '' ? codename : 'n/a'
  end
end
