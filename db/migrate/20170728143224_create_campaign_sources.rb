class CreateCampaignSources < ActiveRecord::Migration
  def change
    create_table :campaign_sources do |t|
      t.string :codename
      t.timestamps
    end

    add_column :campaign_views, :campaign_source_id, :integer, :index => true
    remove_column :campaign_views, :source

    Campaign.reset_column_information
    CampaignView.reset_column_information
    CampaignSource.reset_column_information

    generic_source = CampaignSource.where(codename: nil).first_or_create

    CampaignView.all.each do |cview|
      cview.update_attribute( :campaign_source, generic_source)
    end

  end
end
