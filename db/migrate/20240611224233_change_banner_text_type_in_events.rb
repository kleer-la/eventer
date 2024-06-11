class ChangeBannerTextTypeInEvents < ActiveRecord::Migration[7.1]
  def change
    change_column :events, :banner_text, :text
  end
end
