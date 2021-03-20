class AddMarketingInfoToParticipant < ActiveRecord::Migration[4.2]
  def change
    add_column :participants, :campaign_id, :integer, :index => true
    add_column :participants, :campaign_source_id, :integer, :index => true

    generic_source = CampaignSource.where(codename: nil).first_or_create
    generic_campaign = Campaign.where(codename: nil).first_or_create

    Participant.reset_column_information

    Participant.all.each do |participant|
      participant.update_attribute( :campaign_source, generic_source)
      participant.update_attribute( :campaign, generic_campaign)
    end

  end
end
