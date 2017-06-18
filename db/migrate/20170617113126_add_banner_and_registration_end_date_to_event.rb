class AddBannerAndRegistrationEndDateToEvent < ActiveRecord::Migration
  def change
    add_column :events, :banner_text, :string
    add_column :events, :banner_type, :string
    add_column :events, :registration_ends, :date
  end
end
